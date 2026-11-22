; Constants for the Epoch sound driver disassemblies (Doraemon, Dragon Slayer I).
; Only EQUs, no macros.

; sound registers
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

; track struct fields (offsets into wSndCh1 etc.)
DEF TRK_STATUS    EQU $00 ; 0 off, 1 released/rest, 2 sounding; SndUpdate sets
                          ; 4 ending, 5 release, 6 key on (SndOutput subtracts 4)
DEF TRK_PTR       EQU $01 ; word: data pointer
DEF TRK_COUNT     EQU $03 ; word: row counter, -= tempo every frame
DEF TRK_NOTE      EQU $05 ; current note number (pitch deltas apply to this)
DEF TRK_NR0       EQU $06 ; register shadow NRx0..NRx4 (5 bytes)
DEF TRK_NR1       EQU $07
DEF TRK_NR2       EQU $08
DEF TRK_NR3       EQU $09
DEF TRK_NR4       EQU $0A
DEF TRK_ENVMODE   EQU $0B ; instrument mode 0-3
DEF TRK_ENVPARAM  EQU $0C ; mode 1/2: rate; mode 3: gate (word)
DEF TRK_ENVCOUNT  EQU $0D ; mode 1/2: frame counter
DEF TRK_ENVPTR    EQU $0E ; word. mode 1: volume step list; mode 3: gate countdown
DEF TRK_ENVINDEX  EQU $10 ; mode 1: step index
DEF TRK_LOOPDEPTH EQU $11
DEF TRK_LOOPSTACK EQU $12 ; 3 frames of 4 bytes: pass, passes, return address
DEF TRK_START     EQU $1E ; word, Dragon Slayer only: first byte of the track
