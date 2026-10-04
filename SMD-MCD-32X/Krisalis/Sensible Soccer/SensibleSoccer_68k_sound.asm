; Generated from the ROM by tools/mdis.py (capstone) + m68k_ss.py.
; Syntax: asm68k-style; RAM and module addresses as equates.

Snd_Mailbox              equ  $FFFEFE   ; long: $A00000 + Z80 mailbox address (read from Z80 $0004)
Snd_IsNTSC               equ  $FFFF04   ; 1 = 60 Hz console: every 6th frame is skipped
Snd_NTSCSkip             equ  $FFFF06   ; frame counter 0-5 for the NTSC skip
Snd_SlowMode             equ  $FFFF08   ; game flag: 1 = also skip every 6th frame (5/6 tempo); set for order position 2
Snd_SlowSkip             equ  $FFFF0A   ; frame counter for Snd_SlowMode
Snd_PauseReq             equ  $FFFF0C   ; 1 = pause, 2 = resume (handled by the next update)
Snd_Paused               equ  $FFFF0E   ; $FF while paused
Snd_MusicReq             equ  $FFFF10   ; order position + 1 requested by Snd_PlayMusic
Snd_MusicTick            equ  $FFFF12   ; frames since the last music row
Snd_MusicOrder           equ  $FFFF14   ; current order position (song)
Snd_MusicRow             equ  $FFFF16   ; row 0-63 in the current patterns
Snd_SFXOrder             equ  $FFFF18   ; order position + 1 of the SFX sequence (0 = off)
Snd_SFXRow               equ  $FFFF1A   ; row of the SFX sequence
Snd_SFXTick              equ  $FFFF1C   ; frames since the last SFX-sequence row
Snd_SFXSpeed             equ  $FFFF1E   ; SFX-sequence speed
Snd_PendRate             equ  $FFFF20   ; pending direct sample: rate (non-zero = pending)
Snd_PendLen              equ  $FFFF22   ; pending direct sample: length
Snd_PendAddr             equ  $FFFF24   ; pending direct sample: $8000 | (addr & $7FFF)
Snd_PendBank             equ  $FFFF26   ; pending direct sample: ROM bank (addr >> 15)
Snd_JingleOrder          equ  $FFFF28   ; order position of the jingle
Snd_JingleRow            equ  $FFFF2A   ; row of the jingle
Snd_FetchRow             equ  $FFFF2C   ; row used by ReadCell
Snd_MusicSpeed           equ  $FFFF2E   ; music speed: a row every speed+1 frames
Snd_Busy                 equ  $FFFF30   ; $FF while Snd_Update runs (or while paused)
Snd_InJingle             equ  $FFFF32   ; $FF while the jingle column is being read (commands act on the jingle)
Snd_JingleActive         equ  $FFFF34   ; $FF while a jingle plays
Snd_JingleTick           equ  $FFFF36   ; frames since the last jingle row
Snd_JingleSpeed          equ  $FFFF38   ; jingle speed
Snd_JingleReq            equ  $FFFF3A   ; order position + 1 requested by Snd_PlayJingle
Snd_MusicChan            equ  $FFFF3C   ; 6 x 12 bytes, music channel readers
Snd_JingleChan           equ  $FFFF84   ; 12 bytes, jingle reader (column 4 = FM5)
Snd_SFXChan              equ  $FFFF90   ; 12 bytes, SFX-sequence reader (column 5 = FM6/DAC)
Snd_MusicVol             equ  $FFFF9C   ; music attenuation (byte)
Snd_JingleVol            equ  $FFFF9E   ; jingle attenuation (byte)
Snd_Z80Held              equ  $FFFFA0   ; $FF while the 68k holds the Z80 bus
Snd_StopJingle           equ  $FFFFA2   ; $FF: stop the jingle (set by Snd_PlayMusic)
Snd_SavedJingle          equ  $FFFFA4   ; mailbox +1 saved over a pause
Snd_SFXBusy              equ  $FFFFA6   ; copy of the Z80 SFX-busy flag
Mod_Samples              equ  $075BFE   ; module: 8 x (offset.w, length.w)
Mod_OrderFlag            equ  $075C1E   ; module: $FFFF = word order entries, 0 = byte
Mod_Patterns             equ  $075C20   ; module: pattern pointer table
Mod_Orders               equ  $075DAC   ; module: order list (6 bytes per row)
Mod_Voices               equ  $077390   ; voice bank (64 x 32 bytes)

	org	$6D982


; ==========================================================================
;  Krisalis sound module (Shaun Hollingworth) -- 68k side, revision 2
;  Sensible Soccer (E) (M4): code $06D982-$06E4E1, Z80 driver $06E4E2,
;                  music module $075BFE (order list with BYTE entries),
;                  8 samples in bank $0F = $078000-$07FFFF, voices $077390.
;  Same sequencer as Boogerman / Mickey Mania, without the jump table,
;  the volume/position query functions, the pans and the extra-sample
;  player.  Snd_SlowMode (set by the game for order position 2) slows the
;  update to 5/6 speed.  The game calls the functions directly:
;    Snd_PlayMusic(0, 2, $0F, $2D), Snd_PlayJingle($0E, $14, $17, $18),
;    Snd_PlaySFXSeq($15, $16, $34, $35).
; ==========================================================================
Snd_IsJinglePlaying:
	tst.w    Snd_JingleActive                          ; 06D982  Z flag clear while a jingle plays
	rts                                                ; 06D988
Snd_IsSFXSamplePlaying:
	tst.w    Snd_SFXBusy                               ; 06D98A  Z flag clear while an SFX sample plays
	rts                                                ; 06D990
Snd_Pause:
	move.w   #$1,Snd_PauseReq                          ; 06D992  request pause; Snd_Busy keeps the update idle until Snd_Resume
	st.b     Snd_Paused                                ; 06D99A
	rts                                                ; 06D9A0
Snd_Resume:
	tst.w    Snd_Busy                                  ; 06D9A2  only if paused: request resume
	beq.b    Snd_Resume_exit                           ; 06D9A8
	move.w   #$2,Snd_PauseReq                          ; 06D9AA
	sf.b     Snd_Busy                                  ; 06D9B2
	sf.b     Snd_Paused                                ; 06D9B8
Snd_Resume_exit:
	rts                                                ; 06D9BE
Snd_Init:
	move.w   sr,-(a7)                                  ; 06D9C0  clear the module RAM (interrupts off)
	move.w   #$2700,sr                                 ; 06D9C2
	lea.l    Snd_Mailbox,a0                            ; 06D9C6
	lea.l    ($FFFFA8).l,a1                            ; 06D9CC
	move.w   #$A9,d7                                   ; 06D9D2
Snd_Init_clr:
	clr.b    (a0)+                                     ; 06D9D6
	dbra     d7,Snd_Init_clr                           ; 06D9D8
	move.w   #$0,Snd_SlowMode                          ; 06D9DC
	nop                                                ; 06D9E4
	bsr.w    Z80_LoadDriver                            ; 06D9E6  reset Z80, run the boot stub, upload the driver
	move.w   #$400,d7                                  ; 06D9EA
Snd_Init_delay:
	dbra     d7,Snd_Init_delay                         ; 06D9EE
	bsr.w    Snd_StopZ80                               ; 06D9F2
	clr.w    Snd_IsNTSC                                ; 06D9F6  PAL/NTSC: bit 6 of the version register = 1 on PAL
	btst.b   #$6,($A10001).l                           ; 06D9FC
	bne.b    Snd_Init_pal                              ; 06DA04
	addq.w   #$1,Snd_IsNTSC                            ; 06DA06
Snd_Init_pal:
	moveq    #$0,d0                                    ; 06DA0C  read the mailbox pointer from Z80 $0004/$0005
	move.b   ($A00005).l,d0                            ; 06DA0E
	rol.l    #$8,d0                                    ; 06DA14
	move.b   ($A00004).l,d0                            ; 06DA16
	addi.l   #$A00000,d0                               ; 06DA1C
	move.l   d0,Snd_Mailbox                            ; 06DA22
	bsr.w    Snd_StartZ80                              ; 06DA28  release the Z80
	bsr.w    Z80_UploadBanks                           ; 06DA2C  upload the voice bank and sample table
	move.w   (a7)+,sr                                  ; 06DA30
	rts                                                ; 06DA32
Unused_6DA34:
	sf.b     Snd_Busy                                  ; 06DA34  (orphaned code, never executed)
	clr.w    Snd_PauseReq                              ; 06DA3A
Snd_PlayMusic:
	addq.w   #$1,d0                                    ; 06DA40  d0 = order position (0 / 1 = silence); also stops a jingle and resets the music volume
	move.w   d0,Snd_MusicReq                           ; 06DA42
	st.b     Snd_StopJingle                            ; 06DA48
	sf.b     Snd_MusicChan+$38                         ; 06DA4E
	clr.b    Snd_MusicVol                              ; 06DA54
	clr.w    Snd_PauseReq                              ; 06DA5A
	clr.w    Snd_Paused                                ; 06DA60
	sf.b     Snd_Busy                                  ; 06DA66
	rts                                                ; 06DA6C
Snd_PlayJingle:
	tst.w    Snd_Paused                                ; 06DA6E  d0 = order position of the jingle (column 4 is played on FM5)
	bne.b    Snd_PlayJingle_exit                       ; 06DA74
	addq.w   #$1,d0                                    ; 06DA76
	move.w   d0,Snd_JingleReq                          ; 06DA78
	sf.b     Snd_Busy                                  ; 06DA7E
Snd_PlayJingle_exit:
	rts                                                ; 06DA84
Snd_PlaySFXSeq:
	addq.w   #$1,d0                                    ; 06DA86  d0 = order position of the SFX sequence (column 5 = drum samples)
	move.w   d0,Snd_SFXOrder                           ; 06DA88
	clr.w    Snd_SFXRow                                ; 06DA8E
	bsr.w    ClearSFXChan                              ; 06DA94
	move.w   #$1,Snd_SFXSpeed                          ; 06DA98  speed 1: a row every 2 frames
	clr.w    Snd_PendRate                              ; 06DAA0
	rts                                                ; 06DAA6

; --------------------------------------------------------------------------
;  Snd_Update (function 0): call once per frame
; --------------------------------------------------------------------------
Snd_Update:
	btst.b   #$0,($A11100).l                           ; 06DAA8  once per frame (VBlank). Works whether or not the caller holds the Z80 bus
	move.w   sr,-(a7)                                  ; 06DAB0
	bne.b    Snd_Update_held                           ; 06DAB2
	move.w   #$0,($A11100).l                           ; 06DAB4
Snd_Update_held:
	bsr.b    Snd_Frame                                 ; 06DABC
	move.w   (a7)+,sr                                  ; 06DABE
	bne.b    Snd_Update_exit                           ; 06DAC0
	move.w   #$100,($A11100).l                         ; 06DAC2
Snd_Update_wait:
	btst.b   #$0,($A11100).l                           ; 06DACA
	bne.b    Snd_Update_wait                           ; 06DAD2
Snd_Update_exit:
	rts                                                ; 06DAD4
Snd_Frame:
	tst.w    Snd_SlowMode                              ; 06DAD6  Snd_SlowMode: skip every 6th frame (tempo x 5/6)
	beq.b    Snd_Frame_ntsc                            ; 06DADC
	addq.w   #$1,Snd_SlowSkip                          ; 06DADE
	cmpi.w   #$6,Snd_SlowSkip                          ; 06DAE4
	bcs.b    Snd_Frame_ntsc                            ; 06DAEC
	clr.w    Snd_SlowSkip                              ; 06DAEE
	rts                                                ; 06DAF4
Snd_Frame_ntsc:
	tst.w    Snd_IsNTSC                                ; 06DAF6  60 Hz: skip every 6th frame so the tempo matches 50 Hz
	beq.b    Snd_Frame_run                             ; 06DAFC
	addq.w   #$1,Snd_NTSCSkip                          ; 06DAFE
	cmpi.w   #$6,Snd_NTSCSkip                          ; 06DB04
	bcs.b    Snd_Frame_run                             ; 06DB0C
	clr.w    Snd_NTSCSkip                              ; 06DB0E
	rts                                                ; 06DB14
Snd_Frame_run:
	tst.b    Snd_Busy                                  ; 06DB16  re-entered or paused?
	beq.b    Snd_Frame_chkpause                        ; 06DB1C
	rts                                                ; 06DB1E
Snd_Frame_chkpause:
	tst.w    Snd_PauseReq                              ; 06DB20  pause/resume request?
	beq.w    Snd_Frame_play                            ; 06DB26
	movem.l  d0-d7/a0-a6,-(a7)                         ; 06DB2A
	move.w   Snd_PauseReq,d0                           ; 06DB2E
	subq.w   #$1,d0                                    ; 06DB34
	beq.b    Snd_Frame_pause                           ; 06DB36
	bsr.w    Z80_WaitIdle                              ; 06DB38  resume: restart voices, restore the jingle state
	move.b   #$7,$0(a6)                                ; 06DB3C
	move.w   Snd_SavedJingle,d0                        ; 06DB42
	move.b   d0,$1(a6)                                 ; 06DB48
	bsr.w    Snd_StartZ80                              ; 06DB4C
	sf.b     Snd_Busy                                  ; 06DB50
	clr.w    Snd_PauseReq                              ; 06DB56
	movem.l  (a7)+,d0-d7/a0-a6                         ; 06DB5C
	rts                                                ; 06DB60
Snd_Frame_pause:
	st.b     Snd_Busy                                  ; 06DB62  pause: save jingle state, silence, stop the SFX sequence
	clr.w    Snd_PauseReq                              ; 06DB68
	bsr.w    Z80_WaitIdle                              ; 06DB6E
	move.b   $1(a6),d0                                 ; 06DB72
	move.w   d0,Snd_SavedJingle                        ; 06DB76
	clr.b    $1(a6)                                    ; 06DB7C
	bsr.w    Z80_CmdSilence                            ; 06DB80
	bsr.w    Snd_StartZ80                              ; 06DB84
	clr.w    Snd_SFXOrder                              ; 06DB88
	bsr.w    Snd_StartZ80                              ; 06DB8E
	movem.l  (a7)+,d0-d7/a0-a6                         ; 06DB92
	rts                                                ; 06DB96
Snd_Frame_play:
	movem.l  d0-d7/a0-a6,-(a7)                         ; 06DB98  normal frame
	st.b     Snd_Busy                                  ; 06DB9C
	move.w   Snd_JingleReq,d0                          ; 06DBA2  jingle requested?
	beq.b    Snd_Frame_music                           ; 06DBA8
	subq.w   #$1,d0                                    ; 06DBAA
	cmpi.w   #$FF,d0                                   ; 06DBAC  (position $FF is treated as 0)
	bne.b    Snd_Frame_jingle                          ; 06DBB0
	moveq    #$0,d0                                    ; 06DBB2
Snd_Frame_jingle:
	move.w   d0,Snd_JingleOrder                        ; 06DBB4
	clr.w    Snd_JingleReq                             ; 06DBBA
	clr.w    Snd_JingleSpeed                           ; 06DBC0
	clr.w    Snd_JingleRow                             ; 06DBC6
	clr.w    Snd_JingleTick                            ; 06DBCC
	bsr.w    ClearJingleChan                           ; 06DBD2  clear the jingle reader
	st.b     Snd_JingleActive                          ; 06DBD6
	movea.l  Snd_Mailbox,a6                            ; 06DBDC
	bsr.w    Snd_StopZ80                               ; 06DBE2  mailbox: jingle volume, jingle on, jingle voice bank 0
	move.b   Snd_JingleVol,$3C(a6)                     ; 06DBE6
	st.b     $1(a6)                                    ; 06DBEE
	sf.b     $F(a6)                                    ; 06DBF2
	bsr.w    Snd_StartZ80                              ; 06DBF6
Snd_Frame_music:
	move.w   Snd_MusicReq,d0                           ; 06DBFA  music requested?
	beq.b    Snd_Frame_sfxseq                          ; 06DC00
	subq.w   #$1,d0                                    ; 06DC02
	move.w   d0,Snd_MusicOrder                         ; 06DC04
	clr.w    Snd_MusicRow                              ; 06DC0A
	move.w   #$6,Snd_MusicSpeed                        ; 06DC10  default speed 6 (7 frames per row)
	bsr.w    ClearMusicChans                           ; 06DC18
	movea.l  Snd_Mailbox,a6                            ; 06DC1C
	bsr.w    Snd_StopZ80                               ; 06DC22
	sf.b     $1(a6)                                    ; 06DC26  mailbox: jingle off, music volume 0
	sf.b     Snd_MusicChan+$38                         ; 06DC2A
	sf.b     $3A(a6)                                   ; 06DC30
	bsr.w    Snd_StartZ80                              ; 06DC34
	bsr.w    Z80_CmdReset                              ; 06DC38  Z80: reset channel state, silence
	bsr.w    Z80_CmdSilence                            ; 06DC3C
	bsr.w    ClearMusicChans                           ; 06DC40
	clr.w    Snd_MusicReq                              ; 06DC44  mailbox: music voice bank 0
	bsr.w    Snd_StopZ80                               ; 06DC4A
	sf.b     $E(a6)                                    ; 06DC4E
	bsr.w    Snd_StartZ80                              ; 06DC52
	bra.b    Snd_Frame_exit                            ; 06DC56
Snd_Frame_sfxseq:
	move.w   Snd_SFXOrder,d0                           ; 06DC58  SFX sequence running?
	beq.b    Snd_Frame_pending                         ; 06DC5E
	bsr.w    SFXSeq_Update                             ; 06DC60
Snd_Frame_pending:
	tst.w    Snd_PendRate                              ; 06DC64  direct sample waiting?
	beq.b    Snd_Frame_musictick                       ; 06DC6A
	bsr.w    SendPendingSample                         ; 06DC6C
Snd_Frame_musictick:
	addq.w   #$1,Snd_MusicTick                         ; 06DC70  music tick
	move.w   Snd_MusicSpeed,d0                         ; 06DC76
	cmp.w    Snd_MusicTick,d0                          ; 06DC7C
	bcc.b    Snd_Frame_between                         ; 06DC82
	clr.w    Snd_MusicTick                             ; 06DC84
	bsr.w    Music_ReadRow                             ; 06DC8A  read 6 cells
	addq.w   #$1,Snd_MusicRow                          ; 06DC8E
	cmpi.w   #$40,Snd_MusicRow                         ; 06DC94
	bcs.b    Snd_Frame_rowdone                         ; 06DC9C
	clr.w    Snd_MusicRow                              ; 06DC9E  end of pattern: next order position
	addq.w   #$1,Snd_MusicOrder                        ; 06DCA4
	bsr.w    ClearMusicChans                           ; 06DCAA
Snd_Frame_rowdone:
	bsr.w    Jingle_OnRow                              ; 06DCAE  jingle row (overrides FM5) and send the row
	bsr.w    Z80_SendRow                               ; 06DCB2
	bra.b    Snd_Frame_exit                            ; 06DCB6
Snd_Frame_between:
	bsr.w    Jingle_OffRow                             ; 06DCB8  no music row: jingle-only row or a tick
	beq.b    Snd_Frame_tickonly                        ; 06DCBC
	bsr.w    Z80_SendRow                               ; 06DCBE
	bra.b    Snd_Frame_exit                            ; 06DCC2
Snd_Frame_tickonly:
	bsr.w    Z80_SendTick                              ; 06DCC4
Snd_Frame_exit:
	sf.b     Snd_Busy                                  ; 06DCC8
	movem.l  (a7)+,d0-d7/a0-a6                         ; 06DCCE
	rts                                                ; 06DCD2

; --------------------------------------------------------------------------
;  Jingle (column 4 of the order list, played on FM5)
; --------------------------------------------------------------------------
Jingle_OnRow:
	bsr.b    Jingle_Step                               ; 06DCD4  jingle row read? then its cell replaces the FM5 cell
	bne.b    Jingle_CopyCell                           ; 06DCD6
	rts                                                ; 06DCD8
Jingle_CopyCell:
	move.w   Snd_JingleChan+$04,Snd_MusicChan+$34      ; 06DCDA
	moveq    #$1,d0                                    ; 06DCE4
	rts                                                ; 06DCE6
Jingle_OffRow:
	bsr.b    Jingle_Step                               ; 06DCE8  jingle-only row: clear the other cells so nothing re-triggers
	beq.b    Jingle_OffRow_none                        ; 06DCEA
	clr.w    Snd_MusicChan+$04                         ; 06DCEC
	clr.w    Snd_MusicChan+$10                         ; 06DCF2
	clr.w    Snd_MusicChan+$1C                         ; 06DCF8
	clr.w    Snd_MusicChan+$28                         ; 06DCFE
	clr.w    Snd_MusicChan+$40                         ; 06DD04
	bra.w    Jingle_CopyCell                           ; 06DD0A
Jingle_OffRow_none:
	rts                                                ; 06DD0E
Jingle_Step:
	lea.l    Snd_JingleChan,a5                         ; 06DD10  a5 = jingle reader, a3 = music reader of FM5
	lea.l    Snd_MusicChan+$30,a3                      ; 06DD16
	tst.w    Snd_StopJingle                            ; 06DD1C  stop requested?
	bne.w    Jingle_Step_stop                          ; 06DD22
	tst.w    Snd_JingleActive                          ; 06DD26
	beq.w    Jingle_Step_exit                          ; 06DD2C
	clr.w    $4(a5)                                    ; 06DD30  clear the jingle cell; clear the FM5 music cell unless it is a command
	move.b   $5(a3),d1                                 ; 06DD34
	lsr.b    #$1,d1                                    ; 06DD38
	cmpi.b   #$7C,d1                                   ; 06DD3A
	bcc.b    Jingle_Step_active                        ; 06DD3E
	clr.w    $4(a3)                                    ; 06DD40
Jingle_Step_active:
	st.b     Snd_InJingle                              ; 06DD44
	st.b     $A(a3)                                    ; 06DD4A  mute the music reader of FM5 (its commands still run)
	move.w   Snd_JingleOrder,d0                        ; 06DD4E  order column 4
	move.w   Snd_JingleRow,Snd_FetchRow                ; 06DD54
	lea.l    Mod_Orders+4,a0                           ; 06DD5E
	tst.w    Mod_OrderFlag                             ; 06DD64
	beq.b    Jingle_Step_chk                           ; 06DD6A
	lea.l    Mod_Orders+8,a0                           ; 06DD6C
Jingle_Step_chk:
	move.w   #$0,d7                                    ; 06DD72
	addq.w   #$1,Snd_JingleTick                        ; 06DD76
	move.w   Snd_JingleSpeed,d4                        ; 06DD7C
	cmp.w    Snd_JingleTick,d4                         ; 06DD82
	bcc.b    Jingle_Step_norow                         ; 06DD88
	clr.w    Snd_JingleTick                            ; 06DD8A
	bsr.w    ReadOrderRow                              ; 06DD90
	addq.w   #$1,Snd_JingleRow                         ; 06DD94
	cmpi.w   #$40,Snd_JingleRow                        ; 06DD9A
	bcs.b    Jingle_Step_row                           ; 06DDA2
	bsr.w    ClearJingleChan                           ; 06DDA4  end of pattern
	clr.w    Snd_JingleRow                             ; 06DDA8
	addq.w   #$1,Snd_JingleOrder                       ; 06DDAE
	tst.w    Snd_JingleOrder                           ; 06DDB4  wrapped to 0 ($7E 00): end of jingle, force the FM5 instrument on the next music note
	bne.b    Jingle_Step_row                           ; 06DDBA
	st.b     $8(a3)                                    ; 06DDBC
Jingle_Step_stop:
	sf.b     Snd_StopJingle                            ; 06DDC0  end of jingle
	sf.b     $A(a3)                                    ; 06DDC6
	clr.w    Snd_JingleActive                          ; 06DDCA
	bsr.w    Snd_StopZ80                               ; 06DDD0
	movea.l  Snd_Mailbox,a6                            ; 06DDD4
	sf.b     $1(a6)                                    ; 06DDDA
	bsr.w    Snd_StartZ80                              ; 06DDDE
	moveq    #$0,d0                                    ; 06DDE2
	sf.b     Snd_InJingle                              ; 06DDE4
	rts                                                ; 06DDEA
Jingle_Step_row:
	sf.b     Snd_InJingle                              ; 06DDEC
	moveq    #$1,d0                                    ; 06DDF2
	rts                                                ; 06DDF4
Jingle_Step_norow:
	sf.b     Snd_InJingle                              ; 06DDF6
	moveq    #$0,d0                                    ; 06DDFC
Jingle_Step_exit:
	rts                                                ; 06DDFE

; --------------------------------------------------------------------------
;  Pattern reading.  Reader (a5, 12 bytes):
;    +0 rows skipped by RLE   +2 empty rows left   +4/5 cell to send (lo,hi)
;    +6 last instrument*8     +8 force instrument  +A muted (FM5 during a jingle)
; --------------------------------------------------------------------------
Music_ReadRow:
	move.w   Snd_MusicOrder,d0                         ; 06DE00  music: all 6 columns of the order row
	move.w   Snd_MusicRow,Snd_FetchRow                 ; 06DE06
	lea.l    Snd_MusicChan,a5                          ; 06DE10
	move.w   #$5,d7                                    ; 06DE16
	lea.l    Mod_Orders,a0                             ; 06DE1A
ReadOrderRow:
	tst.w    Mod_OrderFlag                             ; 06DE20  d0 = order position, a0 = order column, d7 = columns-1, a5 = readers
	beq.b    ReadOrderRow_bytes                        ; 06DE26  word or byte order entries (module flag at +$20)
	add.w    d0,d0                                     ; 06DE28
ReadOrderRow_bytes:
	andi.l   #$FFFF,d0                                 ; 06DE2A
	mulu.w   #$6,d0                                    ; 06DE30  6 entries per order row
	adda.w   d0,a0                                     ; 06DE34
ReadOrderRow_chan:
	moveq    #$0,d0                                    ; 06DE36
	tst.w    Mod_OrderFlag                             ; 06DE38
	beq.b    ReadOrderRow_byte                         ; 06DE3E
	move.w   (a0)+,d0                                  ; 06DE40
	bra.b    ReadOrderRow_got                          ; 06DE42
ReadOrderRow_byte:
	move.b   (a0)+,d0                                  ; 06DE44
ReadOrderRow_got:
	bsr.b    ReadCell                                  ; 06DE46
	lea.l    $C(a5),a5                                 ; 06DE48
	dbra     d7,ReadOrderRow_chan                      ; 06DE4C
	rts                                                ; 06DE50
ReadCell:
	tst.w    $2(a5)                                    ; 06DE52  d0 = pattern number, a5 = reader
	beq.b    ReadCell_fetch                            ; 06DE56  inside a run of empty rows?
	subq.w   #$1,$2(a5)                                ; 06DE58
	addq.w   #$1,$0(a5)                                ; 06DE5C
	rts                                                ; 06DE60
ReadCell_fetch:
	lsl.w    #$2,d0                                    ; 06DE62  pattern address from the pattern table
	lea.l    Mod_Patterns,a1                           ; 06DE64
	adda.w   d0,a1                                     ; 06DE6A
	movea.l  (a1),a1                                   ; 06DE6C
	move.w   Snd_FetchRow,d0                           ; 06DE6E  + 2*(row - rows skipped)
	sub.w    $0(a5),d0                                 ; 06DE74
	add.w    d0,d0                                     ; 06DE78
	adda.w   d0,a1                                     ; 06DE7A
	moveq    #$0,d0                                    ; 06DE7C
	moveq    #$0,d1                                    ; 06DE7E
	move.b   (a1)+,d0                                  ; 06DE80
	move.b   (a1)+,d1                                  ; 06DE82
	cmpi.b   #$FF,d1                                   ; 06DE84  "lo,$FF" = lo+1 empty rows (lo = 0: one empty row)
	bne.b    ReadCell_decode                           ; 06DE88
	tst.b    d0                                        ; 06DE8A
	beq.b    ReadCell_empty                            ; 06DE8C
	move.w   d0,$2(a5)                                 ; 06DE8E
ReadCell_empty:
	moveq    #$0,d0                                    ; 06DE92
	moveq    #$0,d1                                    ; 06DE94
ReadCell_decode:
	tst.w    $A(a5)                                    ; 06DE96  reader muted (FM5 during a jingle)?
	bne.b    ReadCell_chkcmd                           ; 06DE9A
	tst.w    $8(a5)                                    ; 06DE9C  force the last instrument into the cell (after a jingle)
	beq.b    ReadCell_store                            ; 06DEA0
	move.b   d1,d2                                     ; 06DEA2
	lsr.b    #$1,d2                                    ; 06DEA4
	cmpi.b   #$7C,d2                                   ; 06DEA6
	bcc.b    ReadCell_store                            ; 06DEAA
	moveq    #$0,d3                                    ; 06DEAC
	move.b   d0,d2                                     ; 06DEAE
	move.b   d1,d3                                     ; 06DEB0
	lsl.w    #$8,d3                                    ; 06DEB2
	or.b     d2,d3                                     ; 06DEB4
	andi.w   #$1F0,d3                                  ; 06DEB6
	bne.b    ReadCell_forced                           ; 06DEBA
	moveq    #$0,d2                                    ; 06DEBC
	move.b   $6(a5),d2                                 ; 06DEBE
	lsl.w    #$1,d2                                    ; 06DEC2
	or.b     d2,d0                                     ; 06DEC4
	lsr.w    #$8,d2                                    ; 06DEC6
	or.b     d2,d1                                     ; 06DEC8
ReadCell_forced:
	clr.w    $8(a5)                                    ; 06DECA
ReadCell_store:
	move.b   d0,$4(a5)                                 ; 06DECE  cell to send
	move.b   d1,$5(a5)                                 ; 06DED2
ReadCell_chkcmd:
	move.b   d1,d2                                     ; 06DED6  N >= $7C: command handled here
	lsr.b    #$1,d1                                    ; 06DED8
	cmpi.b   #$7C,d1                                   ; 06DEDA
	bcc.b    PatternCommand                            ; 06DEDE
	roxr.b   #$1,d2                                    ; 06DEE0  remember the instrument (I*8)
	roxr.b   #$1,d0                                    ; 06DEE2
	andi.b   #$F8,d0                                   ; 06DEE4
	beq.b    ReadCell_exit                             ; 06DEE8
	move.b   d0,$6(a5)                                 ; 06DEEA
ReadCell_exit:
	rts                                                ; 06DEEE
PatternCommand:
	cmpi.b   #$7C,d1                                   ; 06DEF0  $7C: nothing (Z80 FMS), $7D speed, $7E jump, $7F break
	beq.w    PatternCommand_cmd7C                      ; 06DEF4
	cmpi.b   #$7D,d1                                   ; 06DEF8
	beq.b    PatternCommand_cmd7D                      ; 06DEFC
	cmpi.b   #$7E,d1                                   ; 06DEFE
	beq.b    PatternCommand_cmd7E                      ; 06DF02
	tst.w    Snd_InJingle                              ; 06DF04  $7F: pattern break (row := 63)
	beq.b    PatternCommand_breakmusic                 ; 06DF0A
	move.w   #$3F,Snd_JingleRow                        ; 06DF0C
	rts                                                ; 06DF14
PatternCommand_breakmusic:
	move.w   #$3F,Snd_MusicRow                         ; 06DF16
	rts                                                ; 06DF1E
PatternCommand_cmd7E:
	subq.w   #$1,d0                                    ; 06DF20  $7E: jump to order position lo (after this row); lo = 0 ends a jingle
	tst.w    Snd_InJingle                              ; 06DF22
	beq.b    PatternCommand_jumpmusic                  ; 06DF28
	move.w   #$3F,Snd_JingleRow                        ; 06DF2A
	move.w   d0,Snd_JingleOrder                        ; 06DF32
	rts                                                ; 06DF38
PatternCommand_jumpmusic:
	move.w   d0,Snd_MusicOrder                         ; 06DF3A
	move.w   #$3F,Snd_MusicRow                         ; 06DF40
	rts                                                ; 06DF48
PatternCommand_cmd7D:
	movea.l  Snd_Mailbox,a6                            ; 06DF4A  $7D: speed = lo & $7F, bit 7 = upper voice bank (mailbox +$E / +$F)
	bsr.w    Snd_StopZ80                               ; 06DF50
	tst.w    Snd_InJingle                              ; 06DF54
	beq.b    PatternCommand_musicspeed                 ; 06DF5A
	clr.b    $F(a6)                                    ; 06DF5C
	btst     #$7,d0                                    ; 06DF60
	beq.b    PatternCommand_jinglespeed                ; 06DF64
	st.b     $F(a6)                                    ; 06DF66
PatternCommand_jinglespeed:
	bsr.w    Snd_StartZ80                              ; 06DF6A
	andi.w   #$7F,d0                                   ; 06DF6E
	move.w   d0,Snd_JingleSpeed                        ; 06DF72
	move.w   d0,Snd_JingleTick                         ; 06DF78
	rts                                                ; 06DF7E
PatternCommand_musicspeed:
	clr.b    $E(a6)                                    ; 06DF80
	btst     #$7,d0                                    ; 06DF84
	sf.b     $E(a6)                                    ; 06DF88
	beq.b    PatternCommand_setspeed                   ; 06DF8C
	st.b     $E(a6)                                    ; 06DF8E
PatternCommand_setspeed:
	bsr.w    Snd_StartZ80                              ; 06DF92
	andi.w   #$7F,d0                                   ; 06DF96
	move.w   d0,Snd_MusicSpeed                         ; 06DF9A
PatternCommand_cmd7C:
	rts                                                ; 06DFA0
ClearMusicChans:
	clr.w    Snd_MusicChan+$02                         ; 06DFA2  clear skip/RLE counters of the 6 music readers
	clr.w    Snd_MusicChan                             ; 06DFA8
	clr.w    Snd_MusicChan+$0E                         ; 06DFAE
	clr.w    Snd_MusicChan+$0C                         ; 06DFB4
	clr.w    Snd_MusicChan+$1A                         ; 06DFBA
	clr.w    Snd_MusicChan+$18                         ; 06DFC0
	clr.w    Snd_MusicChan+$26                         ; 06DFC6
	clr.w    Snd_MusicChan+$24                         ; 06DFCC
	clr.w    Snd_MusicChan+$32                         ; 06DFD2
	clr.w    Snd_MusicChan+$30                         ; 06DFD8
	clr.w    Snd_MusicChan+$3E                         ; 06DFDE
	clr.w    Snd_MusicChan+$3C                         ; 06DFE4
	rts                                                ; 06DFEA
ClearJingleChan:
	clr.w    Snd_JingleChan+$02                        ; 06DFEC
	clr.w    Snd_JingleChan                            ; 06DFF2
	rts                                                ; 06DFF8
ClearSFXChan:
	clr.w    Snd_SFXChan+$02                           ; 06DFFA
	clr.w    Snd_SFXChan                               ; 06E000
	rts                                                ; 06E006

; --------------------------------------------------------------------------
;  SFX sequence (column 5: drum samples only)
; --------------------------------------------------------------------------
SFXSeq_Update:
	subq.w   #$1,d0                                    ; 06E008  d0 = SFX order position + 1
	lea.l    Snd_SFXChan,a5                            ; 06E00A
	lea.l    Mod_Orders+5,a0                           ; 06E010  order column 5
	tst.w    Mod_OrderFlag                             ; 06E016
	beq.b    SFXSeq_Update_chk                         ; 06E01C
	lea.l    Mod_Orders+10,a0                          ; 06E01E
SFXSeq_Update_chk:
	addq.w   #$1,Snd_SFXTick                           ; 06E024
	move.w   Snd_SFXSpeed,d4                           ; 06E02A
	cmp.w    Snd_SFXTick,d4                            ; 06E030
	bcc.b    SFXSeq_Update_notyet                      ; 06E036
	clr.w    Snd_SFXTick                               ; 06E038
	bsr.w    SFXSeq_ReadRow                            ; 06E03E
	addq.w   #$1,Snd_SFXRow                            ; 06E042
	cmpi.w   #$40,Snd_SFXRow                           ; 06E048
	bcs.b    SFXSeq_Update_exit                        ; 06E050
	clr.w    Snd_SFXChan+$02                           ; 06E052
	clr.w    Snd_SFXChan                               ; 06E058
	bsr.w    ClearSFXChan                              ; 06E05E
	clr.w    Snd_SFXRow                                ; 06E062  end of pattern: next position, 0 = end
	addq.w   #$1,Snd_SFXOrder                          ; 06E068
	tst.w    Snd_SFXOrder                              ; 06E06E
	bne.b    SFXSeq_Update_exit                        ; 06E074
	bsr.w    SFXSeq_End                                ; 06E076
	rts                                                ; 06E07A
SFXSeq_Update_exit:
	rts                                                ; 06E07C
SFXSeq_Update_notyet:
	rts                                                ; 06E07E
SFXSeq_End:
	move.w   #$1,d2                                    ; 06E080  end of sequence: cut the sample (1 byte from Z80 address 0)
	move.w   #$0,d0                                    ; 06E084
	move.w   #$FF,d1                                   ; 06E088
	bra.w    SendDrumSample                            ; 06E08C
SFXSeq_ReadRow:
	tst.w    Mod_OrderFlag                             ; 06E090
	beq.b    SFXSeq_ReadRow_bytes                      ; 06E096
	add.w    d0,d0                                     ; 06E098
SFXSeq_ReadRow_bytes:
	mulu.w   #$6,d0                                    ; 06E09A
	adda.w   d0,a0                                     ; 06E09E
	moveq    #$0,d0                                    ; 06E0A0
	tst.w    Mod_OrderFlag                             ; 06E0A2
	beq.b    SFXSeq_ReadRow_byte                       ; 06E0A8
	move.w   (a0)+,d0                                  ; 06E0AA
	bra.b    SFXSeq_ReadRow_got                        ; 06E0AC
SFXSeq_ReadRow_byte:
	move.b   (a0)+,d0                                  ; 06E0AE
SFXSeq_ReadRow_got:
	tst.w    $2(a5)                                    ; 06E0B0
	beq.b    SFXSeq_ReadRow_fetch                      ; 06E0B4
	subq.w   #$1,$2(a5)                                ; 06E0B6
	addq.w   #$1,$0(a5)                                ; 06E0BA
	rts                                                ; 06E0BE
SFXSeq_ReadRow_fetch:
	lsl.w    #$2,d0                                    ; 06E0C0
	lea.l    Mod_Patterns,a1                           ; 06E0C2
	adda.w   d0,a1                                     ; 06E0C8
	movea.l  (a1),a1                                   ; 06E0CA
	move.w   Snd_SFXRow,d0                             ; 06E0CC
	sub.w    $0(a5),d0                                 ; 06E0D2
	add.w    d0,d0                                     ; 06E0D6
	adda.w   d0,a1                                     ; 06E0D8
	moveq    #$0,d0                                    ; 06E0DA
	moveq    #$0,d1                                    ; 06E0DC
	move.b   (a1)+,d0                                  ; 06E0DE
	move.b   (a1)+,d1                                  ; 06E0E0
	cmpi.b   #$FF,d1                                   ; 06E0E2
	bne.b    SFXSeq_ReadRow_decode                     ; 06E0E6
	tst.b    d0                                        ; 06E0E8
	beq.b    SFXSeq_ReadRow_empty                      ; 06E0EA
	move.w   d0,$2(a5)                                 ; 06E0EC
SFXSeq_ReadRow_empty:
	moveq    #$0,d0                                    ; 06E0F0
	moveq    #$0,d1                                    ; 06E0F2
SFXSeq_ReadRow_decode:
	move.b   d1,d2                                     ; 06E0F4  only N $6D-$74 (samples) and commands are used here
	lsr.b    #$1,d1                                    ; 06E0F6
	cmpi.b   #$7C,d1                                   ; 06E0F8
	bcc.b    SFXSeq_ReadRow_cmd                        ; 06E0FC
	subi.b   #$6D,d1                                   ; 06E0FE
	bcs.b    SFXSeq_ReadRow_exit                       ; 06E102
	cmpi.b   #$8,d1                                    ; 06E104
	bcc.b    SFXSeq_ReadRow_exit                       ; 06E108
	lea.l    Mod_Samples,a1                            ; 06E10A  module sample table
	andi.w   #$FF,d1                                   ; 06E110
	add.w    d1,d1                                     ; 06E114
	add.w    d1,d1                                     ; 06E116
	adda.w   d1,a1                                     ; 06E118
	move.w   d0,d1                                     ; 06E11A  d1 = rate (cell lo byte)
	move.w   (a1),d0                                   ; 06E11C
	ori.w    #$8000,d0                                 ; 06E11E
	move.w   $2(a1),d2                                 ; 06E122
	bsr.w    SendDrumSample                            ; 06E126
SFXSeq_ReadRow_exit:
	rts                                                ; 06E12A
SFXSeq_ReadRow_cmd:
	cmpi.b   #$7C,d1                                   ; 06E12C
	beq.w    SFXSeq_ReadRow_cmd7C                      ; 06E130
	cmpi.b   #$7D,d1                                   ; 06E134
	beq.b    SFXSeq_ReadRow_cmd7D                      ; 06E138
	cmpi.b   #$7E,d1                                   ; 06E13A
	beq.b    SFXSeq_ReadRow_cmd7E                      ; 06E13E
	move.w   #$3F,Snd_SFXRow                           ; 06E140
	rts                                                ; 06E148
SFXSeq_ReadRow_cmd7E:
	subq.w   #$1,d0                                    ; 06E14A  $7E: next position lo-1 ($7E 00 = end)
	move.w   #$3F,Snd_SFXRow                           ; 06E14C
	move.w   d0,Snd_SFXOrder                           ; 06E154
	rts                                                ; 06E15A
SFXSeq_ReadRow_cmd7D:
	movea.l  Snd_Mailbox,a6                            ; 06E15C  $7D: speed
	bsr.w    Snd_StopZ80                               ; 06E162
	andi.w   #$7F,d0                                   ; 06E166
	move.w   d0,Snd_SFXSpeed                           ; 06E16A
	move.w   d0,Snd_SFXTick                            ; 06E170
	rts                                                ; 06E176
SFXSeq_ReadRow_cmd7C:
	rts                                                ; 06E178
	dc.b     $26,$00,$E0,$8B,$EE,$8B,$02,$40,$7F,$FF,$00,$40,$80,$00,$60,$04; 06E17A
	dc.b     $36,$3C,$00,$0F,$33,$C1,$00,$FF,$FF,$20,$33,$C0,$00,$FF,$FF,$24; 06E18A
	dc.b     $33,$C2,$00,$FF,$FF,$22,$33,$C3,$00,$FF,$FF,$26,$4E,$75; 06E19A
SendPendingSample:
	clr.w    Snd_SFXOrder                              ; 06E1A8  send a direct sample (nothing in this game sets Snd_PendRate)
	clr.w    Snd_SFXRow                                ; 06E1AE
	move.w   Snd_PendRate,d1                           ; 06E1B4
	move.w   Snd_PendAddr,d0                           ; 06E1BA
	move.w   Snd_PendLen,d2                            ; 06E1C0
	move.w   Snd_PendBank,d3                           ; 06E1C6
	clr.w    Snd_PendRate                              ; 06E1CC
	bra.b    SendSample                                ; 06E1D2
SendDrumSample:
	move.b   #$F,d3                                    ; 06E1D4  drum from the module: music sample bank $0F
SendSample:
	tst.w    Snd_Paused                                ; 06E1D8  d0 = addr, d1 = rate, d2 = length, d3 = bank
	bne.b    SendSample_exit                           ; 06E1DE  not while paused
	movea.l  Snd_Mailbox,a6                            ; 06E1E0
	bsr.w    Snd_StopZ80                               ; 06E1E6
	move.b   d0,$10(a6)                                ; 06E1EA
	lsr.w    #$8,d0                                    ; 06E1EE
	move.b   d0,$11(a6)                                ; 06E1F0
	move.b   d1,$12(a6)                                ; 06E1F4
	move.b   d2,$14(a6)                                ; 06E1F8
	lsr.w    #$8,d2                                    ; 06E1FC
	move.b   d2,$15(a6)                                ; 06E1FE
	st.b     $16(a6)                                   ; 06E202  trigger (Z80 starts it from its wait loop)
	move.b   d3,$42(a6)                                ; 06E206
	bsr.w    Snd_StartZ80                              ; 06E20A
SendSample_exit:
	rts                                                ; 06E20E
Z80_BootStub:
	dc.b     $F3,$AF,$32,$00,$10,$11,$06,$09,$7B       ; 06E210  27 bytes: di / xor a / ld ($1000),a / ld de,<bank> / 9x bank bit / ld a,$FF / ld ($1000),a / jr $
	dc.b     $E6,$01,$32,$00,$60,$CB,$1A,$CB,$1B       ; 06E219
	dc.b     $10,$F4,$3E,$FF,$32,$00,$10,$18,$FE       ; 06E222
	dc.b     $00                                       ; 06E22B
Z80_ResetHold:
	move.w   #$100,($A11100).l                         ; 06E22C
	move.w   #$0,($A11200).l                           ; 06E234
	moveq    #$9,d0                                    ; 06E23C
Z80_ResetHold_dly:
	nop                                                ; 06E23E
	dbra     d0,Z80_ResetHold_dly                      ; 06E240
	move.w   #$100,($A11200).l                         ; 06E244
	rts                                                ; 06E24C
Z80_LoadDriver:
	bsr.b    Z80_ResetHold                             ; 06E24E  stub to Z80 $0000 with bank word 0
	lea.l    ($A00000).l,a0                            ; 06E250
	lea.l    Z80_BootStub(pc),a1                       ; 06E256
	moveq    #$5,d7                                    ; 06E25A
Z80_LoadDriver_stub1:
	move.b   (a1)+,(a0)+                               ; 06E25C
	dbra     d7,Z80_LoadDriver_stub1                   ; 06E25E
	move.w   #$0,d0                                    ; 06E262
	move.b   d0,(a0)+                                  ; 06E266
	lsr.w    #$8,d0                                    ; 06E268
	move.b   d0,(a0)+                                  ; 06E26A
	moveq    #$14,d7                                   ; 06E26C
Z80_LoadDriver_stub2:
	move.b   (a1)+,(a0)+                               ; 06E26E
	dbra     d7,Z80_LoadDriver_stub2                   ; 06E270
	bsr.w    Z80_ResetRelease                          ; 06E274
Z80_LoadDriver_waitalive:
	moveq    #$63,d7                                   ; 06E278  wait until the stub has written $FF to $1000
Z80_LoadDriver_dly:
	dbra     d7,Z80_LoadDriver_dly                     ; 06E27A
	move.w   #$100,($A11100).l                         ; 06E27E
Z80_LoadDriver_waitbus:
	btst.b   #$0,($A11100).l                           ; 06E286
	bne.b    Z80_LoadDriver_waitbus                    ; 06E28E
	move.b   ($A01000).l,d0                            ; 06E290
	bne.b    Z80_LoadDriver_upload                     ; 06E296
	move.w   #$0,($A11100).l                           ; 06E298
	bra.b    Z80_LoadDriver_waitalive                  ; 06E2A0
Z80_LoadDriver_upload:
	bsr.w    Z80_ResetHold                             ; 06E2A2  upload $1400 bytes to Z80 $0C00, then patch $0000 = di / jp $0C00
	lea.l    Z80_Driver(pc),a0                         ; 06E2A6
	lea.l    ($A00C00).l,a1                            ; 06E2AA
	move.w   #$13FF,d7                                 ; 06E2B0
Z80_LoadDriver_copy:
	move.b   (a0)+,(a1)+                               ; 06E2B4
	dbra     d7,Z80_LoadDriver_copy                    ; 06E2B6
	move.b   #$F3,($A00000).l                          ; 06E2BA
	move.b   #$C3,($A00001).l                          ; 06E2C2
	move.b   #$0,($A00002).l                           ; 06E2CA
	move.b   #$C,($A00003).l                           ; 06E2D2
	bsr.b    Z80_ResetRelease                          ; 06E2DA
	sf.b     Snd_Z80Held                               ; 06E2DC
	rts                                                ; 06E2E2
Z80_ResetRelease:
	move.w   #$0,($A11200).l                           ; 06E2E4
	move.w   #$0,($A11100).l                           ; 06E2EC
	moveq    #$9,d0                                    ; 06E2F4
Z80_ResetRelease_dly:
	nop                                                ; 06E2F6
	dbra     d0,Z80_ResetRelease_dly                   ; 06E2F8
	move.w   #$100,($A11200).l                         ; 06E2FC
	rts                                                ; 06E304
Snd_StopZ80:
	move.w   sr,-(a7)                                  ; 06E306  request the bus and wait for it (interrupts off meanwhile)
	move.w   #$2700,sr                                 ; 06E308
	move.b   #$1,($A11100).l                           ; 06E30C  request the bus and wait for it
	move.l   d0,-(a7)                                  ; 06E314
Snd_StopZ80_wait:
	move.b   ($A11100).l,d0                            ; 06E316
	andi.b   #$1,d0                                    ; 06E31C
	bne.b    Snd_StopZ80_wait                          ; 06E320
	st.b     Snd_Z80Held                               ; 06E322
	move.l   (a7)+,d0                                  ; 06E328
	move.w   (a7)+,sr                                  ; 06E32A
	rts                                                ; 06E32C
Snd_StartZ80:
	move.b   #$0,($A11100).l                           ; 06E32E
	sf.b     Snd_Z80Held                               ; 06E336
	rts                                                ; 06E33C
Z80_UploadBanks:
	lea.l    Mod_Voices,a1                             ; 06E33E  $800 bytes of voices -> Z80 $0400 (64 voices)
	bsr.w    Z80_WaitIdle                              ; 06E344
	lea.l    ($A00400).l,a0                            ; 06E348
	move.w   #$7FF,d7                                  ; 06E34E
Z80_UploadBanks_voices:
	move.b   (a1)+,(a0)+                               ; 06E352
	dbra     d7,Z80_UploadBanks_voices                 ; 06E354
	move.b   #$2,(a6)                                  ; 06E358  command 2 (reset)
	lea.l    $18(a6),a6                                ; 06E35C
	lea.l    Mod_Samples,a0                            ; 06E360  module sample table -> mailbox +$18
	move.w   #$1F,d7                                   ; 06E366
Z80_UploadBanks_samples:
	move.b   (a0)+,(a6)+                               ; 06E36A
	dbra     d7,Z80_UploadBanks_samples                ; 06E36C
	movea.l  Snd_Mailbox,a0                            ; 06E370  music sample bank
	move.b   #$F,$44(a0)                               ; 06E376  music sample bank $0F ($078000-$07FFFF)
	bsr.w    Snd_StartZ80                              ; 06E37C
	rts                                                ; 06E380
Z80_CmdReset:
	bsr.w    Z80_WaitIdle                              ; 06E382
	move.b   #$2,(a6)                                  ; 06E386
	bsr.w    Snd_StartZ80                              ; 06E38A
	rts                                                ; 06E38E
Z80_CmdSilence:
	bsr.w    Z80_WaitIdle                              ; 06E390
	move.b   #$4,(a6)                                  ; 06E394
	bsr.w    Snd_StartZ80                              ; 06E398
	rts                                                ; 06E39C
Z80_SendTick:
	move.w   Snd_MusicOrder,d0                         ; 06E39E  positions 0 and 1 are silent: no tick unless a jingle plays
	cmpi.w   #$2,d0                                    ; 06E3A4
	bcc.w    Z80_SendTick_tick                         ; 06E3A8
	tst.b    Snd_JingleActive                          ; 06E3AC
	bne.w    Z80_SendTick_tick                         ; 06E3B2
	movea.l  Snd_Mailbox,a6                            ; 06E3B6
	bsr.w    Snd_StopZ80                               ; 06E3BC
	bra.b    Z80_SendTick_status                       ; 06E3C0
Z80_SendTick_tick:
	bsr.w    Z80_WaitIdle                              ; 06E3C2
	move.b   Snd_MusicVol,$3A(a6)                      ; 06E3C6
	move.b   #$1,(a6)                                  ; 06E3CE
Z80_SendTick_status:
	move.b   $38(a6),Snd_SFXBusy                       ; 06E3D2  read the SFX-busy flag back
	moveq    #$0,d0                                    ; 06E3DA  re-check PAL/NTSC
	btst.b   #$6,($A10001).l                           ; 06E3DC
	bne.b    Z80_SendTick_ntsc                         ; 06E3E4
	addq.w   #$1,d0                                    ; 06E3E6
Z80_SendTick_ntsc:
	cmp.w    Snd_IsNTSC,d0                             ; 06E3E8
	beq.b    Z80_SendTick_exit                         ; 06E3EE
	move.w   d0,Snd_IsNTSC                             ; 06E3F0
	clr.w    Snd_NTSCSkip                              ; 06E3F6
Z80_SendTick_exit:
	bsr.w    Snd_StartZ80                              ; 06E3FC
	rts                                                ; 06E400
Z80_SendRow:
	tst.b    Snd_JingleActive                          ; 06E402  new row (command $0A)
	bne.w    Z80_SendRow_send                          ; 06E408
	cmpi.w   #$1,Snd_MusicOrder                        ; 06E40C  position 1: never sent
	bne.w    Z80_SendRow_chkempty                      ; 06E414
	rts                                                ; 06E418
Z80_SendRow_chkempty:
	lea.l    Snd_MusicChan,a0                          ; 06E41A  all six cells empty: nothing to send
	moveq    #$0,d0                                    ; 06E420
	or.w     $4(a0),d0                                 ; 06E422
	or.w     $10(a0),d0                                ; 06E426
	or.w     $1C(a0),d0                                ; 06E42A
	or.w     $28(a0),d0                                ; 06E42E
	or.w     $34(a0),d0                                ; 06E432
	or.w     $40(a0),d0                                ; 06E436
	bne.w    Z80_SendRow_send                          ; 06E43A
	rts                                                ; 06E43E
Z80_SendRow_send:
	bsr.w    Z80_WaitIdle                              ; 06E440
	lea.l    $2(a6),a5                                 ; 06E444
	move.b   $38(a6),Snd_SFXBusy                       ; 06E448
	move.w   #$5,d7                                    ; 06E450
	lea.l    Snd_MusicChan,a0                          ; 06E454
Z80_SendRow_copy:
	move.b   $4(a0),(a5)+                              ; 06E45A  6 cells -> mailbox +2
	move.b   $5(a0),(a5)+                              ; 06E45E
	lea.l    $C(a0),a0                                 ; 06E462
	dbra     d7,Z80_SendRow_copy                       ; 06E466
	move.b   #$A,(a6)                                  ; 06E46A
	bsr.w    Snd_StartZ80                              ; 06E46E
	rts                                                ; 06E472
	dc.b     $2F,$0E,$2C,$79,$00,$FF,$FE,$FE,$61,$00,$FE,$88,$1D,$40,$00,$40; 06E474
	dc.b     $61,$00,$FE,$A8,$2C,$5F,$4E,$75,$2F,$0E,$2C,$79,$00,$FF,$FE,$FE; 06E484
	dc.b     $61,$00,$FE,$70,$1D,$40,$00,$3E,$61,$00,$FE,$90,$2C,$5F,$4E,$75; 06E494
Snd_WaitZ80:
	movem.l  d0/a6,-(a7)                               ; 06E4A4  wait until the Z80 has taken the last command (bus released afterwards by the caller)
	bsr.w    Z80_WaitIdle                              ; 06E4A8  d0 = pan byte for FM5 during jingles (0 = voice pan)
	movem.l  (a7)+,d0/a6                               ; 06E4AC
	rts                                                ; 06E4B0
Z80_WaitIdle:
	movea.l  Snd_Mailbox,a6                            ; 06E4B2  hold the bus until the Z80 has taken the last command; a6 = mailbox
Z80_WaitIdle_wait:
	bsr.w    Snd_StopZ80                               ; 06E4B8
	move.b   (a6),d0                                   ; 06E4BC
	beq.b    Z80_WaitIdle_exit                         ; 06E4BE
	bsr.w    Snd_StartZ80                              ; 06E4C0
	nop                                                ; 06E4C4
	nop                                                ; 06E4C6
	nop                                                ; 06E4C8
	nop                                                ; 06E4CA
	nop                                                ; 06E4CC
	nop                                                ; 06E4CE
	nop                                                ; 06E4D0
	nop                                                ; 06E4D2
	nop                                                ; 06E4D4
	nop                                                ; 06E4D6
	nop                                                ; 06E4D8
	bra.b    Z80_WaitIdle_wait                         ; 06E4DA
	dc.b     $61,$00,$FE,$28                           ; 06E4DC  (dead code: bsr.w Snd_StopZ80)
Z80_WaitIdle_exit:
	rts                                                ; 06E4E0
Z80_Driver:
	incbin  "SensibleSoccer_Z80.bin"                ; 06E4E2  $1400 bytes uploaded to Z80 $0C00, see Kris_Z80_rev2_*.asm
