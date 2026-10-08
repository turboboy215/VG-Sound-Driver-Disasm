HW={0xFF00:'rP1',0xFF01:'rSB',0xFF02:'rSC',0xFF04:'rDIV',0xFF0F:'rIF',0xFFFF:'rIE',0xFF40:'rLCDC',0xFF44:'rLY',
0xFF10:'rNR10',0xFF11:'rNR11',0xFF12:'rNR12',0xFF13:'rNR13',0xFF14:'rNR14',0xFF16:'rNR21',0xFF17:'rNR22',0xFF18:'rNR23',0xFF19:'rNR24',
0xFF1A:'rNR30',0xFF1B:'rNR31',0xFF1C:'rNR32',0xFF1D:'rNR33',0xFF1E:'rNR34',0xFF20:'rNR41',0xFF21:'rNR42',0xFF22:'rNR43',0xFF23:'rNR44',
0xFF24:'rNR50',0xFF25:'rNR51',0xFF26:'rNR52',0xFF4D:'rKEY1',0xFF4F:'rVBK',0xFF70:'rSVBK',0xFF30:'_AUD3WAVERAM'}
def hw_inc():
    out=['; Game Boy hardware registers used by the sound drivers','IF !DEF(GB_HW_INC)','DEF GB_HW_INC EQU 1','']
    for a,n in sorted(HW.items()): out.append(f'DEF {n:<14} EQU ${a:04X}')
    out+=['','ENDC','']
    return '\n'.join(out)
