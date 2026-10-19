"""Names for the Toki Tori sound driver: code labels, RAM, constants."""

SND_BANK = 0x2D

# ---------------------------------------------------------------- hardware
HW = {0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
      0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24',
      0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34',
      0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
      0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52', 0xFF30: '_AUD3WAVERAM',
      0xFF44: 'rLY', 0xFF70: 'rSVBK', 0x2100: 'MBC5_ROMB'}

# ---------------------------------------------------------------- RAM ($DF00-$DFA6, WRAM bank 7)
RAM = [
    (0xDF00, 'wSndBank', 1, 'ROM bank of the driver ($2D); all data banks are relative to it'),
    (0xDF01, 'wSndUnused01', 1, 'set to $0F by Sound_APUOn, never read'),
    (0xDF02, 'wSeqEnabled', 1, 'nonzero: sequencer runs'),
    (0xDF03, 'wTickCounter', 1, 'frames left in the current row'),
    (0xDF04, 'wRowFrame', 1, 'nonzero on the frame a new row starts (= speed)'),
    (0xDF05, 'wRowsLeft', 1, 'rows left in the current order entry'),
    (0xDF06, 'wSongBank', 1, 'bank of the order list'),
    (0xDF07, 'wOrderPtr', 2, 'next order entry'),
    (0xDF09, 'wSpeed', 1, 'frames per row'),
    (0xDF0A, 'wLoopPtr', 2, 'order entry to restart at after $FF'),
    (0xDF0C, 'wSongStart', 2, 'first order entry (base for FX_POS_JUMP)'),
    (0xDF0E, 'wSfxTimer', 1, 'frames left in the current SFX step (0 = no SFX)'),
    (0xDF0F, 'wSfxBank', 1, ''),
    (0xDF10, 'wSfxPtr', 2, ''),
    (0xDF12, 'wSfxChannel', 1, 'channel owned by the SFX ($FF = none)'),
    (0xDF13, 'wSfxNewChannel', 1, 'channel of a just-read SFX step ($FF = none)'),
    (0xDF14, 'wSfxRegs', 5, 'register values of the SFX step'),
    (0xDF19, 'wSndUnused19', 1, ''),
    (0xDF1A, 'wPatPtr1', 3, 'ch1 pattern stream: bank, pointer'),
    (0xDF1D, 'wPatPtr2', 3, ''),
    (0xDF20, 'wPatPtr3', 3, ''),
    (0xDF23, 'wPatPtr4', 3, ''),
]
CH_BASE = [0xDF26, 0xDF47, 0xDF68, 0xDF89]
CH_SIZE = 0x21
# Channel 1-3 structure
CH_FIELDS = [
    (0x00, 'ROWBUF', 5, 'raw row bytes fetched by Seq_FetchRow'),
    (0x05, 'NOTEFLAG', 1, 'cleared by a note, never read'),
    (0x06, 'FXA', 1, 'tick effect A (pitch): offset into the tick table'),
    (0x07, 'FXB', 1, 'tick effect B (volume): offset into the tick table'),
    (0x08, 'NOTE', 1, 'current note (porta target)'),
    (0x09, 'PREVNOTE', 1, 'previous note (porta: current sliding note)'),
    (0x0A, 'SFXFLAG', 1, '0 music, 1 SFX starts, $FF SFX owns the channel'),
    (0x0B, 'RETRIG', 1, 'frames to the next retrigger (1 = next frame)'),
    (0x0C, 'VOLUME', 1, '0-$3F (row data up to 64)'),
    (0x0D, 'INSTR', 1, 'ch1/2 NRx1, ch3 wave number'),
    (0x0E, 'FREQ', 2, 'period, little-endian'),
    (0x10, 'FINETUNE', 1, '1/16 semitone, 8 = in tune'),
    (0x11, 'VIBSPEED', 1, ''),
    (0x12, 'VIBPHASE', 1, '0-63'),
    (0x13, 'VIBPTR', 2, 'vibrato table pointer (lo, hi)'),
    (0x15, 'ARPCOUNT', 1, ''),
    (0x16, 'ARPX', 1, ''),
    (0x17, 'ARPY', 1, ''),
    (0x18, 'SLIDEUP', 1, ''),
    (0x19, 'SLIDEDOWN', 1, ''),
    (0x1A, 'PORTASPEED', 1, ''),
    (0x1B, 'TREMSPEED', 1, ''),
    (0x1C, 'TREMPHASE', 1, '0-31'),
    (0x1D, 'TREMPTR', 2, 'tremolo table pointer (lo, hi)'),
    (0x1F, 'TREMBASE', 1, 'volume tremolo works around'),
    (0x20, 'VOLSLIDE', 1, 'xy: up x / down y per tick'),
]
# Channel 4 has its own layout inside the same 33 bytes
CH4_FIELDS = [
    (0x00, 'ROWBUF', 5, ''), (0x05, 'NOTEFLAG', 1, 'cleared by a note, never read'),
    (0x06, 'FXA', 1, 'always 0 (no pitch effects)'), (0x07, 'FXB', 1, ''),
    (0x0A, 'SFXFLAG', 1, ''), (0x0B, 'RETRIG', 1, ''), (0x0C, 'VOLUME', 1, ''),
    (0x0D, 'INSTR', 1, 'NR43 value'),
    (0x10, 'FINETUNE', 1, 'set to 8 by Driver_Init, never read'),
    (0x11, 'TREMSPEED', 1, ''), (0x12, 'TREMPHASE', 1, ''), (0x13, 'TREMPTR', 2, ''),
    (0x15, 'TREMBASE', 1, ''), (0x16, 'VOLSLIDE', 1, ''),
]

def ram_symbols():
    """addr -> (expr) for every byte."""
    s = {}
    for a, n, ln, _ in RAM:
        for i in range(ln):
            s[a + i] = n if i == 0 else f'{n}+{i}'
    for ch, base in enumerate(CH_BASE):
        flds = CH4_FIELDS if ch == 3 else CH_FIELDS
        for off, n, ln, _ in flds:
            for i in range(ln):
                nm = f'wCh{ch+1}{n.title().replace("_", "")}'
                nm = f'wCh{ch+1}_{n}'
                s[base + off + i] = nm if i == 0 else f'{nm}+{i}'
        for off in range(CH_SIZE):
            s.setdefault(base + off, f'wCh{ch+1}+${off:02X}')
    return s

# ---------------------------------------------------------------- effects
ROW_FX = ['ARPEGGIO', 'SLIDE_UP', 'SLIDE_DOWN', 'PORTA', 'VIBRATO', 'PORTA_VOLSLIDE',
          'VIB_VOLSLIDE', 'TREMOLO', '08', '09', 'VOLSLIDE', 'POS_JUMP', 'SET_VOL',
          'PAT_BREAK', '0E', 'SPEED'] + \
         ['E0', 'FINE_UP', 'FINE_DOWN', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9',
          'FINE_VOL', 'FINE_VOL_B', 'EC', 'ED', 'EE', 'EF']
TICK_FX = ['NONE', 'ARPEGGIO', 'SLIDE_UP', 'SLIDE_DOWN', 'FINE_UP', 'FINE_DOWN',
           'PORTA_UP', 'PORTA_DOWN', 'VIBRATO', 'TREMOLO', 'VOLSLIDE', 'FINE_VOL']

def camel(s):
    if len(s) == 2:          # E0-EF, 08, 09, 0E: keep as written
        return s
    return ''.join(w.capitalize() for w in s.split('_'))

NOTE_NAMES = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']
def note_name(n):
    if n >= 72:
        return f'${n:02X}'
    return f'{NOTE_NAMES[n % 12]}{2 + n // 12}'

# ---------------------------------------------------------------- code labels
def code_labels():
    L = {}
    # home bank
    L.update({0x3D00: 'Sound_SelectBank', 0x3D0A: 'Sound_APUOn', 0x3D1C: 'Sound_Stop',
              0x3D2C: 'Sound_Update', 0x3D4B: 'Sound_PlaySfx', 0x3D6C: 'Sfx_Update',
              0x3D9E: 'Sound_PlaySong', 0x3DD8: 'Seq_NextOrder', 0x3E12: 'Seq_SetPatPtr',
              0x3E1C: 'Seq_Loop', 0x3E2D: 'Seq_Tick', 0x3E63: 'Seq_NewRow',
              0x3E6F: 'Seq_FetchRow', 0x3F80: 'RowLenTable_80'})
    # bank $2D
    L.update({0x6248: 'Driver_Init', 0x62CB: 'Music_Update', 0x62DD: 'Music_UnusedRet',
              0x62DE: 'Music_TickEffects', 0x6327: 'CallTickFx', 0x632B: 'Sfx_Claim',
              0x6353: 'Sfx_Release', 0x636E: 'Sfx_ChanFlagPtr',
              0x6381: 'Ch1_Output', 0x63CB: 'Ch2_Output', 0x640C: 'Ch3_Output', 0x6474: 'Ch4_Output',
              0x64AF: 'UnusedRet_64AF', 0x64B0: 'TickFx_None',
              0x41F6: 'Ch4_UnusedRet',
              0x4000: 'Ch1_RowFxTable', 0x4100: 'Ch1_TickFxTable', 0x4200: 'Ch2_RowFxTable',
              0x4300: 'Ch2_TickFxTable', 0x4400: 'Ch3_RowFxTable', 0x4500: 'Ch3_TickFxTable',
              0x4600: 'Ch4_RowFxTable', 0x4700: 'Ch4_TickFxTable',
              0x4800: 'FreqTables', 0x5800: 'WaveTable', 0x5900: 'Ch3VolTable',
              0x5A00: 'TremoloTables', 0x5C00: 'VibratoTables', 0x6000: 'SongTable',
              0x6200: 'SfxTable', 0x4118: 'Ch4_ReadRow'})
    for ch in range(3):
        d = 0x3A8 * ch
        n = f'Ch{ch+1}'
        L[0x64B1 + d] = f'{n}_ReadRow'
        L[0x6704 + d] = f'{n}_SetFreq'
        L[0x6708 + d] = f'{n}_SetFreqFT'
    L[0x66AD] = 'Ch1Fx_VibratoReset_Unused'
    L[0x6A55] = 'Ch2Fx_VibratoReset_Unused'
    L[0x6DFD] = 'Ch3Fx_VibratoReset_Unused'
    return L

# local labels inside the row decoder, by offset from ChN_ReadRow (same layout for ch1-3)
DECODER_LOCALS = {0x2E: '.fullRow', 0x57: '.mNote', 0x88: '.mNoteNoInstr', 0x7B: '.storeVol',
                  0xA0: '.mInstr', 0xB2: '.storeVol2', 0xBF: '.mVol', 0xD1: '.mFx', 0xE1: '.mParam',
                  0xE0: '.jump'}
CH4_LOCALS = {0x4146: '.fullRow', 0x4161: '.mNote', 0x4187: '.mNoteNoInstr', 0x4178: '.storeVol',
              0x419F: '.mInstr', 0x41B1: '.storeVol2', 0x41BE: '.mVol', 0x41D2: '.mFx',
              0x41E2: '.mParam', 0x41E1: '.jump'}
