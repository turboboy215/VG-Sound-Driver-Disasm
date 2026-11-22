; agenda_sound.inc - constants for the Agenda sound driver disassemblies
; (Doraemon 2 (J), Pokonyan! - Yume no Daibouken (J))
; EQUs only - no macros.

; ---- sound hardware registers ----
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
DEF rWAVE EQU $FF30
DEF rIE   EQU $FFFF

; ---- track struct ($30 bytes; 4 music tracks + 1 SFX track) ----
DEF TRK_START     EQU $00 ; word: first byte of the track (cmd $A0 loops here)
DEF TRK_PTR       EQU $02 ; word: data pointer
DEF TRK_ENVBASE   EQU $04 ; word: volume-envelope list (cmd $A8 / drum)
DEF TRK_CALLRET   EQU $06 ; word: address of the $AC pointer (return slot)
DEF TRK_LOOPPTR   EQU $08 ; word: $A3 loop start
DEF TRK_FREQ      EQU $0A ; word: current period (NRx3/NRx4)
DEF TRK_SEQTABLE  EQU $0C ; word: $AB/$AD pointer (ch1 sweep list / ch4 drum kit)
DEF TRK_FLAGS     EQU $0E ; flags, see TRKF_*
DEF TRK_DEFLEN    EQU $0F ; default length (ticks)
DEF TRK_LENGTH    EQU $10 ; ticks left in the current row
DEF TRK_VOLUME    EQU $11 ; ch1/2/4: NRx2 volume nibble; ch3: NR32 value
DEF TRK_DUTY      EQU $12 ; NRx1 value (ch1/2 duty)
DEF TRK_PAN       EQU $13 ; last $A7 argument
DEF TRK_NOTE      EQU $14 ; current note
DEF TRK_TRANSPOSE EQU $15 ; semitones (cmd $B1)
DEF TRK_DETUNE    EQU $16 ; signed period offset (cmd $B0, vibrato)
DEF TRK_PREVNOTE  EQU $17 ; previous note (slur test)
DEF TRK_GATE      EQU $18 ; gate in 1/8ths of the length, 0 = full (cmd $B2)
DEF TRK_GATECOUNT EQU $19 ; ticks until note-off
DEF TRK_LOOPCOUNT EQU $1A ; $A3/$A9 pass counter
DEF TRK_CALLCOUNT EQU $1B ; $AC repeat counter
DEF TRK_ENVPTR    EQU $1C ; word: envelope list position
DEF TRK_SEQPTR    EQU $1E ; word: sweep/noise list position
DEF TRK_SEQCOUNT  EQU $20 ; noise list step countdown
DEF TRK_SEQVALUE  EQU $21 ; last sweep/noise value
DEF TRK_ENVCOUNT  EQU $22 ; envelope step countdown
DEF TRK_ENVVALUE  EQU $23 ; last NRx2 value from the envelope list
DEF TRK_VIBSTEP   EQU $24 ; signed vibrato step
DEF TRK_VIBMODE   EQU $25 ; 0 off, 1 triangle, 2 slide down, 3 slide up
DEF TRK_VIBDELAY  EQU $26 ; delay countdown
DEF TRK_VIBDELAYR EQU $27 ; delay reload
DEF TRK_VIBHALF   EQU $28 ; triangle half-period countdown
DEF TRK_VIBHALFR  EQU $29 ; half-period reload
DEF TRK_VIBRATE   EQU $2A ; ticks between steps, countdown
DEF TRK_VIBRATER  EQU $2B ; rate reload
DEF TRK_VIBDEPTH  EQU $2C ; step size reload
DEF TRK_SIZEOF    EQU $30

; TRK_FLAGS bits
DEF TRKF_SFXOWNED EQU 0 ; (music struct) the SFX is using this channel
DEF TRKF_SLUR     EQU 1 ; previous note had $A4
DEF TRKF_HASENV   EQU 2 ; $A8 envelope list set
DEF TRKF_HASSEQ   EQU 3 ; $AB/$AD table set
DEF TRKF_SEQRUN   EQU 4 ; noise/sweep list running
DEF TRKF_ENVRUN   EQU 5 ; envelope list running
DEF TRKF_CLOBBERED EQU 7 ; (music struct) SFX just ended here, effects paused until next row

; hSndFlags bits
DEF SNDF_SFX      EQU 4 ; SFX playing
DEF SNDF_NOLOOP   EQU 7 ; $A2: tracks stop at $A0 instead of looping
