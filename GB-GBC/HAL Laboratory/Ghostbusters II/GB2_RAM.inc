; Ghostbusters II sound RAM
; per-channel arrays: 8 entries (channels 0-3 music, 4-7 SFX);
; wChPtr, wChEnvPtr, wChLoopPtr, wChReturnPtr and wChPeriod are words indexed by channel*2

DEF wChPtr               EQU $C511
DEF wChEnvPtr            EQU $C521
DEF wChEnvIndex          EQU $C531
DEF wChWait              EQU $C539
DEF wChLength            EQU $C541
DEF wChEnvWait           EQU $C549
DEF wChLoopCount         EQU $C551
DEF wChLoopPtr           EQU $C559
DEF wChReturnPtr         EQU $C569
DEF wChTranspose         EQU $C579
DEF wChAttenuation       EQU $C581
DEF wChDuty              EQU $C589
DEF wChSweep             EQU $C591
DEF wChPeriod            EQU $C599
DEF wChNRx4              EQU $C5A9
DEF wChLastNote          EQU $C5B1
DEF wFastMusic           EQU $D611
DEF hCurBank             EQU $FFAC
DEF hSoundQueueCount     EQU $FFB2
DEF hSoundQueue          EQU $FFB3
DEF hActiveChannels      EQU $FFBD
DEF hChannelsEnded       EQU $FFBE
DEF hChMask              EQU $FFBF
DEF hCurCh               EQU $FFC0
DEF hCurCh2              EQU $FFC1
DEF hCurRegOffset        EQU $FFC2
DEF hStreamPtr           EQU $FFC3
DEF hTemp                EQU $FFC5

; game routines used by the sound code
DEF RST_CopyBytes        EQU $0008
DEF RST_Bankswitch       EQU $0030
DEF FillBytes            EQU $06DA

; hardware registers used by the sound code
DEF rP1 EQU $FF00
DEF rDIV EQU $FF04
DEF rTIMA EQU $FF05
DEF rTMA EQU $FF06
DEF rTAC EQU $FF07
DEF rIF EQU $FF0F
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF _AUD3WAVERAM EQU $FF30
DEF rLCDC EQU $FF40
DEF rSTAT EQU $FF41
DEF rLY EQU $FF44
DEF rDMA EQU $FF46
DEF rIE EQU $FFFF
