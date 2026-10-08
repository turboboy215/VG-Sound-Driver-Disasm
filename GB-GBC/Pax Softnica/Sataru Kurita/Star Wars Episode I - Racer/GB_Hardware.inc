; Game Boy hardware registers used by the sound drivers
IF !DEF(GB_HW_INC)
DEF GB_HW_INC EQU 1

DEF rP1            EQU $FF00
DEF rSB            EQU $FF01
DEF rSC            EQU $FF02
DEF rDIV           EQU $FF04
DEF rIF            EQU $FF0F
DEF rNR10          EQU $FF10
DEF rNR11          EQU $FF11
DEF rNR12          EQU $FF12
DEF rNR13          EQU $FF13
DEF rNR14          EQU $FF14
DEF rNR21          EQU $FF16
DEF rNR22          EQU $FF17
DEF rNR23          EQU $FF18
DEF rNR24          EQU $FF19
DEF rNR30          EQU $FF1A
DEF rNR31          EQU $FF1B
DEF rNR32          EQU $FF1C
DEF rNR33          EQU $FF1D
DEF rNR34          EQU $FF1E
DEF rNR41          EQU $FF20
DEF rNR42          EQU $FF21
DEF rNR43          EQU $FF22
DEF rNR44          EQU $FF23
DEF rNR50          EQU $FF24
DEF rNR51          EQU $FF25
DEF rNR52          EQU $FF26
DEF _AUD3WAVERAM   EQU $FF30
DEF rLCDC          EQU $FF40
DEF rLY            EQU $FF44
DEF rKEY1          EQU $FF4D
DEF rVBK           EQU $FF4F
DEF rSVBK          EQU $FF70
DEF rIE            EQU $FFFF

ENDC
