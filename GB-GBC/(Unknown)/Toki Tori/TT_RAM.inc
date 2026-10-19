; Toki Tori sound RAM: WRAM bank 7, $DF00-$DFA9

DEF wSndBank         EQU $DF00 ; 1 ROM bank of the driver ($2D); all data banks are relative to it
DEF wSndUnused01     EQU $DF01 ; 1 set to $0F by Sound_APUOn, never read
DEF wSeqEnabled      EQU $DF02 ; 1 nonzero: sequencer runs
DEF wTickCounter     EQU $DF03 ; 1 frames left in the current row
DEF wRowFrame        EQU $DF04 ; 1 nonzero on the frame a new row starts (= speed)
DEF wRowsLeft        EQU $DF05 ; 1 rows left in the current order entry
DEF wSongBank        EQU $DF06 ; 1 bank of the order list
DEF wOrderPtr        EQU $DF07 ; 2 next order entry
DEF wSpeed           EQU $DF09 ; 1 frames per row
DEF wLoopPtr         EQU $DF0A ; 2 order entry to restart at after $FF
DEF wSongStart       EQU $DF0C ; 2 first order entry (base for FX_POS_JUMP)
DEF wSfxTimer        EQU $DF0E ; 1 frames left in the current SFX step (0 = no SFX)
DEF wSfxBank         EQU $DF0F ; 1
DEF wSfxPtr          EQU $DF10 ; 2
DEF wSfxChannel      EQU $DF12 ; 1 channel owned by the SFX ($FF = none)
DEF wSfxNewChannel   EQU $DF13 ; 1 channel of a just-read SFX step ($FF = none)
DEF wSfxRegs         EQU $DF14 ; 5 register values of the SFX step
DEF wSndUnused19     EQU $DF19 ; 1
DEF wPatPtr1         EQU $DF1A ; 3 ch1 pattern stream: bank, pointer
DEF wPatPtr2         EQU $DF1D ; 3
DEF wPatPtr3         EQU $DF20 ; 3
DEF wPatPtr4         EQU $DF23 ; 3

; channel structures ($21 bytes each)
DEF CH_SIZE EQU $21
DEF wCh1 EQU $DF26
DEF wCh2 EQU $DF47
DEF wCh3 EQU $DF68
DEF wCh4 EQU $DF89

; ch1-ch3 fields
DEF CH_ROWBUF       EQU $00 ; 5 raw row bytes fetched by Seq_FetchRow
DEF CH_NOTEFLAG     EQU $05 ; 1 cleared by a note, never read
DEF CH_FXA          EQU $06 ; 1 tick effect A (pitch): offset into the tick table
DEF CH_FXB          EQU $07 ; 1 tick effect B (volume): offset into the tick table
DEF CH_NOTE         EQU $08 ; 1 current note (porta target)
DEF CH_PREVNOTE     EQU $09 ; 1 previous note (porta: current sliding note)
DEF CH_SFXFLAG      EQU $0A ; 1 0 music, 1 SFX starts, $FF SFX owns the channel
DEF CH_RETRIG       EQU $0B ; 1 frames to the next retrigger (1 = next frame)
DEF CH_VOLUME       EQU $0C ; 1 0-$3F (row data up to 64)
DEF CH_INSTR        EQU $0D ; 1 ch1/2 NRx1, ch3 wave number
DEF CH_FREQ         EQU $0E ; 2 period, little-endian
DEF CH_FINETUNE     EQU $10 ; 1 1/16 semitone, 8 = in tune
DEF CH_VIBSPEED     EQU $11 ; 1
DEF CH_VIBPHASE     EQU $12 ; 1 0-63
DEF CH_VIBPTR       EQU $13 ; 2 vibrato table pointer (lo, hi)
DEF CH_ARPCOUNT     EQU $15 ; 1
DEF CH_ARPX         EQU $16 ; 1
DEF CH_ARPY         EQU $17 ; 1
DEF CH_SLIDEUP      EQU $18 ; 1
DEF CH_SLIDEDOWN    EQU $19 ; 1
DEF CH_PORTASPEED   EQU $1A ; 1
DEF CH_TREMSPEED    EQU $1B ; 1
DEF CH_TREMPHASE    EQU $1C ; 1 0-31
DEF CH_TREMPTR      EQU $1D ; 2 tremolo table pointer (lo, hi)
DEF CH_TREMBASE     EQU $1F ; 1 volume tremolo works around
DEF CH_VOLSLIDE     EQU $20 ; 1 xy: up x / down y per tick

; ch4 fields (same structure size, different layout)
DEF CH4_ROWBUF      EQU $00 ; 5
DEF CH4_NOTEFLAG    EQU $05 ; 1 cleared by a note, never read
DEF CH4_FXA         EQU $06 ; 1 always 0 (no pitch effects)
DEF CH4_FXB         EQU $07 ; 1
DEF CH4_SFXFLAG     EQU $0A ; 1
DEF CH4_RETRIG      EQU $0B ; 1
DEF CH4_VOLUME      EQU $0C ; 1
DEF CH4_INSTR       EQU $0D ; 1 NR43 value
DEF CH4_FINETUNE    EQU $10 ; 1 set to 8 by Driver_Init, never read
DEF CH4_TREMSPEED   EQU $11 ; 1
DEF CH4_TREMPHASE   EQU $12 ; 1
DEF CH4_TREMPTR     EQU $13 ; 2
DEF CH4_TREMBASE    EQU $15 ; 1
DEF CH4_VOLSLIDE    EQU $16 ; 1

DEF wCh1_ROWBUF       EQU wCh1 + CH_ROWBUF
DEF wCh1_NOTEFLAG     EQU wCh1 + CH_NOTEFLAG
DEF wCh1_FXA          EQU wCh1 + CH_FXA
DEF wCh1_FXB          EQU wCh1 + CH_FXB
DEF wCh1_NOTE         EQU wCh1 + CH_NOTE
DEF wCh1_PREVNOTE     EQU wCh1 + CH_PREVNOTE
DEF wCh1_SFXFLAG      EQU wCh1 + CH_SFXFLAG
DEF wCh1_RETRIG       EQU wCh1 + CH_RETRIG
DEF wCh1_VOLUME       EQU wCh1 + CH_VOLUME
DEF wCh1_INSTR        EQU wCh1 + CH_INSTR
DEF wCh1_FREQ         EQU wCh1 + CH_FREQ
DEF wCh1_FINETUNE     EQU wCh1 + CH_FINETUNE
DEF wCh1_VIBSPEED     EQU wCh1 + CH_VIBSPEED
DEF wCh1_VIBPHASE     EQU wCh1 + CH_VIBPHASE
DEF wCh1_VIBPTR       EQU wCh1 + CH_VIBPTR
DEF wCh1_ARPCOUNT     EQU wCh1 + CH_ARPCOUNT
DEF wCh1_ARPX         EQU wCh1 + CH_ARPX
DEF wCh1_ARPY         EQU wCh1 + CH_ARPY
DEF wCh1_SLIDEUP      EQU wCh1 + CH_SLIDEUP
DEF wCh1_SLIDEDOWN    EQU wCh1 + CH_SLIDEDOWN
DEF wCh1_PORTASPEED   EQU wCh1 + CH_PORTASPEED
DEF wCh1_TREMSPEED    EQU wCh1 + CH_TREMSPEED
DEF wCh1_TREMPHASE    EQU wCh1 + CH_TREMPHASE
DEF wCh1_TREMPTR      EQU wCh1 + CH_TREMPTR
DEF wCh1_TREMBASE     EQU wCh1 + CH_TREMBASE
DEF wCh1_VOLSLIDE     EQU wCh1 + CH_VOLSLIDE

DEF wCh2_ROWBUF       EQU wCh2 + CH_ROWBUF
DEF wCh2_NOTEFLAG     EQU wCh2 + CH_NOTEFLAG
DEF wCh2_FXA          EQU wCh2 + CH_FXA
DEF wCh2_FXB          EQU wCh2 + CH_FXB
DEF wCh2_NOTE         EQU wCh2 + CH_NOTE
DEF wCh2_PREVNOTE     EQU wCh2 + CH_PREVNOTE
DEF wCh2_SFXFLAG      EQU wCh2 + CH_SFXFLAG
DEF wCh2_RETRIG       EQU wCh2 + CH_RETRIG
DEF wCh2_VOLUME       EQU wCh2 + CH_VOLUME
DEF wCh2_INSTR        EQU wCh2 + CH_INSTR
DEF wCh2_FREQ         EQU wCh2 + CH_FREQ
DEF wCh2_FINETUNE     EQU wCh2 + CH_FINETUNE
DEF wCh2_VIBSPEED     EQU wCh2 + CH_VIBSPEED
DEF wCh2_VIBPHASE     EQU wCh2 + CH_VIBPHASE
DEF wCh2_VIBPTR       EQU wCh2 + CH_VIBPTR
DEF wCh2_ARPCOUNT     EQU wCh2 + CH_ARPCOUNT
DEF wCh2_ARPX         EQU wCh2 + CH_ARPX
DEF wCh2_ARPY         EQU wCh2 + CH_ARPY
DEF wCh2_SLIDEUP      EQU wCh2 + CH_SLIDEUP
DEF wCh2_SLIDEDOWN    EQU wCh2 + CH_SLIDEDOWN
DEF wCh2_PORTASPEED   EQU wCh2 + CH_PORTASPEED
DEF wCh2_TREMSPEED    EQU wCh2 + CH_TREMSPEED
DEF wCh2_TREMPHASE    EQU wCh2 + CH_TREMPHASE
DEF wCh2_TREMPTR      EQU wCh2 + CH_TREMPTR
DEF wCh2_TREMBASE     EQU wCh2 + CH_TREMBASE
DEF wCh2_VOLSLIDE     EQU wCh2 + CH_VOLSLIDE

DEF wCh3_ROWBUF       EQU wCh3 + CH_ROWBUF
DEF wCh3_NOTEFLAG     EQU wCh3 + CH_NOTEFLAG
DEF wCh3_FXA          EQU wCh3 + CH_FXA
DEF wCh3_FXB          EQU wCh3 + CH_FXB
DEF wCh3_NOTE         EQU wCh3 + CH_NOTE
DEF wCh3_PREVNOTE     EQU wCh3 + CH_PREVNOTE
DEF wCh3_SFXFLAG      EQU wCh3 + CH_SFXFLAG
DEF wCh3_RETRIG       EQU wCh3 + CH_RETRIG
DEF wCh3_VOLUME       EQU wCh3 + CH_VOLUME
DEF wCh3_INSTR        EQU wCh3 + CH_INSTR
DEF wCh3_FREQ         EQU wCh3 + CH_FREQ
DEF wCh3_FINETUNE     EQU wCh3 + CH_FINETUNE
DEF wCh3_VIBSPEED     EQU wCh3 + CH_VIBSPEED
DEF wCh3_VIBPHASE     EQU wCh3 + CH_VIBPHASE
DEF wCh3_VIBPTR       EQU wCh3 + CH_VIBPTR
DEF wCh3_ARPCOUNT     EQU wCh3 + CH_ARPCOUNT
DEF wCh3_ARPX         EQU wCh3 + CH_ARPX
DEF wCh3_ARPY         EQU wCh3 + CH_ARPY
DEF wCh3_SLIDEUP      EQU wCh3 + CH_SLIDEUP
DEF wCh3_SLIDEDOWN    EQU wCh3 + CH_SLIDEDOWN
DEF wCh3_PORTASPEED   EQU wCh3 + CH_PORTASPEED
DEF wCh3_TREMSPEED    EQU wCh3 + CH_TREMSPEED
DEF wCh3_TREMPHASE    EQU wCh3 + CH_TREMPHASE
DEF wCh3_TREMPTR      EQU wCh3 + CH_TREMPTR
DEF wCh3_TREMBASE     EQU wCh3 + CH_TREMBASE
DEF wCh3_VOLSLIDE     EQU wCh3 + CH_VOLSLIDE

DEF wCh4_ROWBUF       EQU wCh4 + CH4_ROWBUF
DEF wCh4_NOTEFLAG     EQU wCh4 + CH4_NOTEFLAG
DEF wCh4_FXA          EQU wCh4 + CH4_FXA
DEF wCh4_FXB          EQU wCh4 + CH4_FXB
DEF wCh4_SFXFLAG      EQU wCh4 + CH4_SFXFLAG
DEF wCh4_RETRIG       EQU wCh4 + CH4_RETRIG
DEF wCh4_VOLUME       EQU wCh4 + CH4_VOLUME
DEF wCh4_INSTR        EQU wCh4 + CH4_INSTR
DEF wCh4_FINETUNE     EQU wCh4 + CH4_FINETUNE
DEF wCh4_TREMSPEED    EQU wCh4 + CH4_TREMSPEED
DEF wCh4_TREMPHASE    EQU wCh4 + CH4_TREMPHASE
DEF wCh4_TREMPTR      EQU wCh4 + CH4_TREMPTR
DEF wCh4_TREMBASE     EQU wCh4 + CH4_TREMBASE
DEF wCh4_VOLSLIDE     EQU wCh4 + CH4_VOLSLIDE

