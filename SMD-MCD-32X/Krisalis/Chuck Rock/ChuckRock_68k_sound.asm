; Generated from the ROM by tools/mdis.py (capstone) + m68k_cr.py.
; Syntax: asm68k-style; RAM and module addresses as equates.

Snd_Mailbox              equ  $FFFF0008   ; long: $A00000 + Z80 mailbox address (read from Z80 $0004)
Snd_NTSCAdjust           equ  $FFFF000E   ; set by the game after Snd_Init: 1 on 60 Hz consoles, added to every $7D speed
Snd_PauseReq             equ  $FFFF0010   ; 1 = pause, 2 = resume (handled by the next update)
Snd_Paused               equ  $FFFF0012   ; $FF while paused
Snd_MusicReq             equ  $FFFF0014   ; order position + 1 requested by Snd_PlayMusic
Snd_MusicTick            equ  $FFFF0016   ; frames since the last music row
Snd_MusicOrder           equ  $FFFF0018   ; current order position (song)
Snd_MusicRow             equ  $FFFF001A   ; row 0-63 in the current patterns
Snd_SFXOrder             equ  $FFFF001C   ; order position + 1 of the SFX sequence (0 = off)
Snd_SFXRow               equ  $FFFF001E   ; row of the SFX sequence
Snd_SFXTick              equ  $FFFF0020   ; frames since the last SFX-sequence row
Snd_SFXSpeed             equ  $FFFF0022   ; SFX-sequence speed
Snd_PendRate             equ  $FFFF0024   ; pending direct sample: rate (non-zero = pending)
Snd_PendLen              equ  $FFFF0026   ; pending direct sample: length
Snd_PendAddr             equ  $FFFF0028   ; pending direct sample: Z80 address
Snd_JingleOrder          equ  $FFFF002A   ; order position of the jingle
Snd_JingleRow            equ  $FFFF002C   ; row of the jingle
Snd_FetchRow             equ  $FFFF002E   ; row used by ReadCell
Snd_MusicSpeed           equ  $FFFF0030   ; music speed: a row every speed+1 frames
Snd_Busy                 equ  $FFFF0032   ; $FF while Snd_Update runs (or while paused)
Snd_InJingle             equ  $FFFF0034   ; $FF while the jingle column is being read (commands act on the jingle)
Snd_JingleActive         equ  $FFFF0036   ; $FF while a jingle plays
Snd_JingleTick           equ  $FFFF0038   ; frames since the last jingle row
Snd_JingleSpeed          equ  $FFFF003A   ; jingle speed
Snd_JingleReq            equ  $FFFF003C   ; order position + 1 requested by Snd_PlayJingle
Snd_MusicChan            equ  $FFFF003E   ; 6 x 12 bytes, music channel readers
Snd_JingleChan           equ  $FFFF0086   ; 12 bytes, jingle reader (column 4 = FM5)
Snd_SFXChan              equ  $FFFF0092   ; 12 bytes, SFX-sequence reader (column 5 = FM6/DAC)
Snd_Z80Held              equ  $FFFF009E   ; $FF while the 68k holds the Z80 bus
Game_SpeedOffset         equ  $FFFF0002   ; game variable subtracted from every speed (0 in normal play)
Mod_Samples              equ  $018000   ; module: 8 x (offset.w, length.w)
Mod_OrderFlag            equ  $018020   ; module: $FFFF = word order entries, 0 = byte
Mod_Patterns             equ  $018022   ; module: pattern pointer table
Mod_Orders               equ  $018622   ; module: order list (6 words per row)
Mod_Voices               equ  $01BD64   ; voice bank (64 x 32 bytes)

	org	$1C544


; ==========================================================================
;  Krisalis sound module (Shaun Hollingworth) -- 68k side, revision 1
;  Chuck Rock (E): code $01C54E-$01CEA1, Z80 driver $01CEA2,
;                  music module $018000 (8 samples in bank 2 = $010000-$017FFF),
;                  voices $01BD64.
;  The 68k is the sequencer: once per frame Snd_Update advances the music,
;  the jingle (column 4, played on FM5) and the SFX sequence (column 5,
;  drum samples) and sends a row (command $0A) or a tick (command 1).
;  Differences from the later revisions: no volume, pan or 50/60 Hz frame
;  skip (Snd_NTSCAdjust is added to the speed instead), no ROM-bank
;  parameter (the boot stub fixes bank 2), every row/tick is sent.
; ==========================================================================
LevelMusicTable:
	dc.w     $0016,$001F,$0029,$0032,$0039             ; 01C544  order positions of the level tunes (levels 1-5); the title uses 1, "music off" uses 0
Snd_Pause:
	move.w   #$1,Snd_PauseReq                          ; 01C54E  (no caller found in the game)
	st.b     Snd_Paused                                ; 01C556
	rts                                                ; 01C55C
Snd_Resume:
	tst.w    Snd_Busy                                  ; 01C55E  (no caller found in the game)
	beq.b    Snd_Resume_exit                           ; 01C564
	move.w   #$2,Snd_PauseReq                          ; 01C566
	sf.b     Snd_Busy                                  ; 01C56E
	sf.b     Snd_Paused                                ; 01C574
Snd_Resume_exit:
	rts                                                ; 01C57A
Snd_Init:
	move.w   sr,-(a7)                                  ; 01C57C  clear the module RAM (interrupts off)
	move.w   #$2700,sr                                 ; 01C57E
	lea.l    Snd_Mailbox,a0                            ; 01C582
	lea.l    ($FFFF00A0).l,a1                          ; 01C588
	move.w   #$97,d7                                   ; 01C58E
Snd_Init_clr:
	clr.b    (a0)+                                     ; 01C592
	dbra     d7,Snd_Init_clr                           ; 01C594
	move.w   #$0,Snd_NTSCAdjust                        ; 01C598  Snd_NTSCAdjust = 0 (the game sets it afterwards)
	nop                                                ; 01C5A0
	bsr.w    Z80_LoadDriver                            ; 01C5A2  reset Z80, run the boot stub, upload the driver
	move.w   #$400,d7                                  ; 01C5A6
Snd_Init_delay:
	dbra     d7,Snd_Init_delay                         ; 01C5AA
	bsr.w    Snd_StopZ80                               ; 01C5AE
	moveq    #$0,d0                                    ; 01C5B2  read the mailbox pointer from Z80 $0004/$0005
	move.b   ($A00005).l,d0                            ; 01C5B4
	rol.l    #$8,d0                                    ; 01C5BA
	move.b   ($A00004).l,d0                            ; 01C5BC
	addi.l   #$A00000,d0                               ; 01C5C2
	move.l   d0,Snd_Mailbox                            ; 01C5C8
	bsr.w    Snd_StartZ80                              ; 01C5CE  release the Z80
	bsr.w    Z80_UploadBanks                           ; 01C5D2  upload the voice bank and sample table
	move.w   (a7)+,sr                                  ; 01C5D6
	rts                                                ; 01C5D8
Snd_PlayMusic:
	tst.w    Snd_Paused                                ; 01C5DA  d0 = order position; ignored while paused
	bne.b    Snd_PlayMusic_exit                        ; 01C5E0
	addq.w   #$1,d0                                    ; 01C5E2
	move.w   d0,Snd_MusicReq                           ; 01C5E4
	sf.b     Snd_Busy                                  ; 01C5EA
Snd_PlayMusic_exit:
	rts                                                ; 01C5F0
Snd_PlayJingle:
	tst.w    Snd_Paused                                ; 01C5F2  d0 = order position of the jingle (column 4 is played on FM5)
	bne.b    Snd_PlayJingle_exit                       ; 01C5F8
	addq.w   #$1,d0                                    ; 01C5FA
	move.w   d0,Snd_JingleReq                          ; 01C5FC
	sf.b     Snd_Busy                                  ; 01C602
Snd_PlayJingle_exit:
	rts                                                ; 01C608
Snd_PlaySFXSeq:
	addq.w   #$1,d0                                    ; 01C60A  d0 = order position of the SFX sequence (column 5 = drum samples)
	move.w   d0,Snd_SFXOrder                           ; 01C60C
	clr.w    Snd_SFXRow                                ; 01C612
	bsr.w    ClearSFXChan                              ; 01C618
	move.w   #$1,Snd_SFXSpeed                          ; 01C61C  speed 1: a row every 2 frames
	clr.w    Snd_PendRate                              ; 01C624
	rts                                                ; 01C62A
Snd_Update:
	tst.b    Snd_Busy                                  ; 01C62C  once per frame (VBlank); no 50/60 Hz frame skipping in this revision
	beq.b    Snd_Update_chkpause                       ; 01C632
	rts                                                ; 01C634
Snd_Update_chkpause:
	tst.w    Snd_PauseReq                              ; 01C636  pause/resume request?
	beq.w    Snd_Update_play                           ; 01C63C
	movem.l  d0-d7/a0-a6,-(a7)                         ; 01C640
	move.w   Snd_PauseReq,d0                           ; 01C644
	subq.w   #$1,d0                                    ; 01C64A
	beq.b    Snd_Update_pause                          ; 01C64C
	bsr.w    Z80_WaitIdle                              ; 01C64E  resume: restart voices, restore the jingle state
	move.b   #$7,(a6)                                  ; 01C652
	bsr.w    Snd_StartZ80                              ; 01C656
	sf.b     Snd_Busy                                  ; 01C65A
	clr.w    Snd_PauseReq                              ; 01C660
	movem.l  (a7)+,d0-d7/a0-a6                         ; 01C666
	rts                                                ; 01C66A
Snd_Update_pause:
	st.b     Snd_Busy                                  ; 01C66C  pause: save jingle state, silence, stop the SFX sequence
	clr.w    Snd_PauseReq                              ; 01C672
	bsr.w    Z80_WaitIdle                              ; 01C678
	move.b   $1(a6),d0                                 ; 01C67C  keep the jingle state while the Z80 silences everything
	movem.l  d0/a6,-(a7)                               ; 01C680
	clr.b    $1(a6)                                    ; 01C684
	bsr.w    Z80_CmdSilence                            ; 01C688
	bsr.w    Snd_StartZ80                              ; 01C68C
	clr.w    Snd_SFXOrder                              ; 01C690
	move.w   #$190,d0                                  ; 01C696
Snd_Update_dly:
	dbra     d0,Snd_Update_dly                         ; 01C69A
	bsr.w    Snd_StopZ80                               ; 01C69E
	movem.l  (a7)+,d0/a6                               ; 01C6A2
	move.b   d0,$1(a6)                                 ; 01C6A6
	bsr.w    Snd_StartZ80                              ; 01C6AA
	movem.l  (a7)+,d0-d7/a0-a6                         ; 01C6AE
	rts                                                ; 01C6B2
Snd_Update_play:
	movem.l  d0-d7/a0-a6,-(a7)                         ; 01C6B4  normal frame
	st.b     Snd_Busy                                  ; 01C6B8
	move.w   Snd_JingleReq,d0                          ; 01C6BE  jingle requested?
	beq.b    Snd_Update_music                          ; 01C6C4
	subq.w   #$1,d0                                    ; 01C6C6
	cmpi.w   #$FF,d0                                   ; 01C6C8  (position $FF is treated as 0)
	bne.b    Snd_Update_jingle                         ; 01C6CC
	moveq    #$0,d0                                    ; 01C6CE
Snd_Update_jingle:
	move.w   d0,Snd_JingleOrder                        ; 01C6D0
	clr.w    Snd_JingleReq                             ; 01C6D6
	move.w   #$1,Snd_JingleSpeed                       ; 01C6DC  jingle speed 1
	clr.w    Snd_JingleRow                             ; 01C6E4
	bsr.w    ClearJingleChan                           ; 01C6EA  clear the jingle reader
	st.b     Snd_JingleActive                          ; 01C6EE
	movea.l  Snd_Mailbox,a6                            ; 01C6F4
	bsr.w    Snd_StopZ80                               ; 01C6FA  mailbox: jingle on, jingle voice bank 0
	st.b     $1(a6)                                    ; 01C6FE
	sf.b     $F(a6)                                    ; 01C702
	bsr.w    Snd_StartZ80                              ; 01C706
Snd_Update_music:
	move.w   Snd_MusicReq,d0                           ; 01C70A  music requested?
	beq.b    Snd_Update_sfxseq                         ; 01C710
	subq.w   #$1,d0                                    ; 01C712
	move.w   d0,Snd_MusicOrder                         ; 01C714
	clr.w    Snd_MusicRow                              ; 01C71A
	move.w   #$6,Snd_MusicSpeed                        ; 01C720  default speed 6 - Game_SpeedOffset
	move.w   Game_SpeedOffset,d0                       ; 01C728
	sub.w    d0,Snd_MusicSpeed                         ; 01C72E
	bsr.w    ClearMusicChans                           ; 01C734
	bsr.w    Z80_CmdReset                              ; 01C738  Z80: reset channel state, silence
	bsr.w    Z80_CmdSilence                            ; 01C73C
	bsr.w    ClearMusicChans                           ; 01C740
	clr.w    Snd_MusicReq                              ; 01C744  mailbox: music voice bank 0
	bsr.w    Snd_StopZ80                               ; 01C74A
	sf.b     $E(a6)                                    ; 01C74E
	bsr.w    Snd_StartZ80                              ; 01C752
	bra.b    Snd_Update_exit                           ; 01C756
Snd_Update_sfxseq:
	move.w   Snd_SFXOrder,d0                           ; 01C758  SFX sequence running?
	beq.b    Snd_Update_pending                        ; 01C75E
	bsr.w    SFXSeq_Update                             ; 01C760
Snd_Update_pending:
	tst.w    Snd_PendRate                              ; 01C764  direct sample waiting?
	beq.b    Snd_Update_musictick                      ; 01C76A
	bsr.w    SendPendingSample                         ; 01C76C
Snd_Update_musictick:
	addq.w   #$1,Snd_MusicTick                         ; 01C770  music tick
	move.w   Snd_MusicSpeed,d0                         ; 01C776
	cmp.w    Snd_MusicTick,d0                          ; 01C77C
	bcc.b    Snd_Update_between                        ; 01C782
	clr.w    Snd_MusicTick                             ; 01C784
	bsr.w    Music_ReadRow                             ; 01C78A  read 6 cells
	addq.w   #$1,Snd_MusicRow                          ; 01C78E
	cmpi.w   #$40,Snd_MusicRow                         ; 01C794
	bcs.b    Snd_Update_rowdone                        ; 01C79C
	clr.w    Snd_MusicRow                              ; 01C79E  end of pattern: next order position
	addq.w   #$1,Snd_MusicOrder                        ; 01C7A4
	bsr.w    ClearMusicChans                           ; 01C7AA
Snd_Update_rowdone:
	bsr.w    Jingle_OnRow                              ; 01C7AE  jingle row (overrides FM5) and send the row
	bsr.w    Z80_SendRow                               ; 01C7B2
	bra.b    Snd_Update_exit                           ; 01C7B6
Snd_Update_between:
	bsr.w    Jingle_OffRow                             ; 01C7B8  no music row: jingle-only row or a tick
	beq.b    Snd_Update_tickonly                       ; 01C7BC
	bsr.w    Z80_SendRow                               ; 01C7BE
	bra.b    Snd_Update_exit                           ; 01C7C2
Snd_Update_tickonly:
	bsr.w    Z80_SendTick                              ; 01C7C4
Snd_Update_exit:
	sf.b     Snd_Busy                                  ; 01C7C8
	movem.l  (a7)+,d0-d7/a0-a6                         ; 01C7CE
	rts                                                ; 01C7D2

; --------------------------------------------------------------------------
;  Jingle (column 4 of the order list, played on FM5)
; --------------------------------------------------------------------------
Jingle_OnRow:
	bsr.b    Jingle_Step                               ; 01C7D4  jingle row read? then its cell replaces the FM5 cell
	bne.b    Jingle_CopyCell                           ; 01C7D6
	rts                                                ; 01C7D8
Jingle_CopyCell:
	move.w   Snd_JingleChan+$04,Snd_MusicChan+$34      ; 01C7DA
	moveq    #$1,d0                                    ; 01C7E4
	rts                                                ; 01C7E6
Jingle_OffRow:
	bsr.b    Jingle_Step                               ; 01C7E8  jingle-only row: clear the other cells so nothing re-triggers
	beq.b    Jingle_OffRow_none                        ; 01C7EA
	clr.w    Snd_MusicChan+$04                         ; 01C7EC
	clr.w    Snd_MusicChan+$10                         ; 01C7F2
	clr.w    Snd_MusicChan+$1C                         ; 01C7F8
	clr.w    Snd_MusicChan+$28                         ; 01C7FE
	clr.w    Snd_MusicChan+$40                         ; 01C804
	bra.b    Jingle_CopyCell                           ; 01C80A
Jingle_OffRow_none:
	rts                                                ; 01C80C
Jingle_Step:
	tst.w    Snd_JingleActive                          ; 01C80E  only while a jingle plays
	beq.w    Jingle_Step_exit                          ; 01C814
	lea.l    Snd_JingleChan,a5                         ; 01C818  a5 = jingle reader, a3 = music reader of FM5
	lea.l    Snd_MusicChan+$30,a3                      ; 01C81E
	clr.w    $4(a5)                                    ; 01C824  clear the jingle cell; clear the FM5 music cell unless it is a command
	move.b   $5(a3),d1                                 ; 01C828
	lsr.b    #$1,d1                                    ; 01C82C
	cmpi.b   #$7C,d1                                   ; 01C82E
	bcc.b    Jingle_Step_active                        ; 01C832
	clr.w    $4(a3)                                    ; 01C834
Jingle_Step_active:
	st.b     Snd_InJingle                              ; 01C838
	st.b     $A(a3)                                    ; 01C83E  mute the music reader of FM5 (its commands still run)
	move.w   Snd_JingleOrder,d0                        ; 01C842  order column 4
	move.w   Snd_JingleRow,Snd_FetchRow                ; 01C848
	lea.l    Mod_Orders+4(pc),a0                       ; 01C852
	tst.w    Mod_OrderFlag                             ; 01C856
	beq.b    Jingle_Step_chk                           ; 01C85C
	lea.l    Mod_Orders+8(pc),a0                       ; 01C85E
Jingle_Step_chk:
	move.w   #$0,d7                                    ; 01C862
	addq.w   #$1,Snd_JingleTick                        ; 01C866
	move.w   Snd_JingleSpeed,d4                        ; 01C86C
	cmp.w    Snd_JingleTick,d4                         ; 01C872
	bcc.b    Jingle_Step_norow                         ; 01C878
	clr.w    Snd_JingleTick                            ; 01C87A
	bsr.w    ReadOrderRow                              ; 01C880
	addq.w   #$1,Snd_JingleRow                         ; 01C884
	cmpi.w   #$40,Snd_JingleRow                        ; 01C88A
	bcs.b    Jingle_Step_row                           ; 01C892
	bsr.w    ClearJingleChan                           ; 01C894  end of pattern
	clr.w    Snd_JingleRow                             ; 01C898
	addq.w   #$1,Snd_JingleOrder                       ; 01C89E
	tst.w    Snd_JingleOrder                           ; 01C8A4  wrapped to 0 ($7E 00): end of jingle, force the FM5 instrument on the next music note
	bne.b    Jingle_Step_row                           ; 01C8AA
	st.b     $8(a3)                                    ; 01C8AC
	sf.b     $A(a3)                                    ; 01C8B0  end of jingle
	clr.w    Snd_JingleActive                          ; 01C8B4
	bsr.w    Snd_StopZ80                               ; 01C8BA
	movea.l  Snd_Mailbox,a6                            ; 01C8BE
	sf.b     $1(a6)                                    ; 01C8C4
	bsr.w    Snd_StartZ80                              ; 01C8C8
	moveq    #$0,d0                                    ; 01C8CC
	sf.b     Snd_InJingle                              ; 01C8CE
	rts                                                ; 01C8D4
Jingle_Step_row:
	sf.b     Snd_InJingle                              ; 01C8D6
	moveq    #$1,d0                                    ; 01C8DC
	rts                                                ; 01C8DE
Jingle_Step_norow:
	sf.b     Snd_InJingle                              ; 01C8E0
	moveq    #$0,d0                                    ; 01C8E6
Jingle_Step_exit:
	rts                                                ; 01C8E8

; --------------------------------------------------------------------------
;  Pattern reading.  Reader (a5, 12 bytes):
;    +0 rows skipped by RLE   +2 empty rows left   +4/5 cell to send (lo,hi)
;    +6 last instrument*8     +8 force instrument  +A muted (FM5 during a jingle)
; --------------------------------------------------------------------------
Music_ReadRow:
	move.w   Snd_MusicOrder,d0                         ; 01C8EA  music: all 6 columns of the order row
	move.w   Snd_MusicRow,Snd_FetchRow                 ; 01C8F0
	lea.l    Snd_MusicChan+$00,a5                      ; 01C8FA
	move.w   #$5,d7                                    ; 01C900
	lea.l    Mod_Orders(pc),a0                         ; 01C904
ReadOrderRow:
	tst.w    Mod_OrderFlag                             ; 01C908  d0 = order position, a0 = order column, d7 = columns-1, a5 = readers
	beq.b    ReadOrderRow_bytes                        ; 01C90E  word or byte order entries (module flag at +$20)
	add.w    d0,d0                                     ; 01C910
ReadOrderRow_bytes:
	mulu.w   #$6,d0                                    ; 01C912  6 entries per order row
	adda.w   d0,a0                                     ; 01C916
ReadOrderRow_chan:
	moveq    #$0,d0                                    ; 01C918
	tst.w    Mod_OrderFlag                             ; 01C91A
	beq.b    ReadOrderRow_byte                         ; 01C920
	move.w   (a0)+,d0                                  ; 01C922
	bra.b    ReadOrderRow_got                          ; 01C924
ReadOrderRow_byte:
	move.b   (a0)+,d0                                  ; 01C926
ReadOrderRow_got:
	bsr.b    ReadCell                                  ; 01C928
	lea.l    $C(a5),a5                                 ; 01C92A
	dbra     d7,ReadOrderRow_chan                      ; 01C92E
	rts                                                ; 01C932
ReadCell:
	tst.w    $2(a5)                                    ; 01C934  d0 = pattern number, a5 = reader
	beq.b    ReadCell_fetch                            ; 01C938  inside a run of empty rows?
	subq.w   #$1,$2(a5)                                ; 01C93A
	addq.w   #$1,(a5)                                  ; 01C93E
	rts                                                ; 01C940
ReadCell_fetch:
	lsl.w    #$2,d0                                    ; 01C942  pattern address from the pattern table
	lea.l    Mod_Patterns(pc),a1                       ; 01C944
	adda.w   d0,a1                                     ; 01C948
	movea.l  (a1),a1                                   ; 01C94A
	move.w   Snd_FetchRow,d0                           ; 01C94C  + 2*(row - rows skipped)
	sub.w    (a5),d0                                   ; 01C952
	add.w    d0,d0                                     ; 01C954
	adda.w   d0,a1                                     ; 01C956
	moveq    #$0,d0                                    ; 01C958
	moveq    #$0,d1                                    ; 01C95A
	move.b   (a1)+,d0                                  ; 01C95C
	move.b   (a1)+,d1                                  ; 01C95E
	cmpi.b   #$FF,d1                                   ; 01C960  "lo,$FF" = lo+1 empty rows (lo = 0: one empty row)
	bne.b    ReadCell_decode                           ; 01C964
	tst.b    d0                                        ; 01C966
	beq.b    ReadCell_empty                            ; 01C968
	move.w   d0,$2(a5)                                 ; 01C96A
ReadCell_empty:
	moveq    #$0,d0                                    ; 01C96E
	moveq    #$0,d1                                    ; 01C970
ReadCell_decode:
	tst.w    $A(a5)                                    ; 01C972  reader muted (FM5 during a jingle)?
	bne.b    ReadCell_chkcmd                           ; 01C976
	tst.w    $8(a5)                                    ; 01C978  force the last instrument into the cell (after a jingle)
	beq.b    ReadCell_store                            ; 01C97C
	move.b   d1,d2                                     ; 01C97E
	lsr.b    #$1,d2                                    ; 01C980
	cmpi.b   #$7C,d2                                   ; 01C982
	bcc.b    ReadCell_store                            ; 01C986
	moveq    #$0,d3                                    ; 01C988
	move.b   d0,d2                                     ; 01C98A
	move.b   d1,d3                                     ; 01C98C
	lsl.w    #$8,d3                                    ; 01C98E
	or.b     d2,d3                                     ; 01C990
	andi.w   #$1F0,d3                                  ; 01C992
	bne.b    ReadCell_forced                           ; 01C996
	moveq    #$0,d2                                    ; 01C998
	move.b   $6(a5),d2                                 ; 01C99A
	lsl.w    #$1,d2                                    ; 01C99E
	or.b     d2,d0                                     ; 01C9A0
	lsr.w    #$8,d2                                    ; 01C9A2
	or.b     d2,d1                                     ; 01C9A4
ReadCell_forced:
	clr.w    $8(a5)                                    ; 01C9A6
ReadCell_store:
	move.b   d0,$4(a5)                                 ; 01C9AA  cell to send
	move.b   d1,$5(a5)                                 ; 01C9AE
ReadCell_chkcmd:
	move.b   d1,d2                                     ; 01C9B2  N >= $7C: command handled here
	lsr.b    #$1,d1                                    ; 01C9B4
	cmpi.b   #$7C,d1                                   ; 01C9B6
	bcc.b    PatternCommand                            ; 01C9BA
	roxr.b   #$1,d2                                    ; 01C9BC  remember the instrument (I*8)
	roxr.b   #$1,d0                                    ; 01C9BE
	andi.b   #$F8,d0                                   ; 01C9C0
	beq.b    ReadCell_exit                             ; 01C9C4
	move.b   d0,$6(a5)                                 ; 01C9C6
ReadCell_exit:
	rts                                                ; 01C9CA
PatternCommand:
	cmpi.b   #$7C,d1                                   ; 01C9CC  $7C: nothing (Z80 FMS), $7D speed, $7E jump, $7F break
	beq.w    PatternCommand_cmd7C                      ; 01C9D0
	cmpi.b   #$7D,d1                                   ; 01C9D4
	beq.b    PatternCommand_cmd7D                      ; 01C9D8
	cmpi.b   #$7E,d1                                   ; 01C9DA
	beq.b    PatternCommand_cmd7E                      ; 01C9DE
	tst.w    Snd_InJingle                              ; 01C9E0  $7F: pattern break (row := 63)
	beq.b    PatternCommand_breakmusic                 ; 01C9E6
	move.w   #$3F,Snd_JingleRow                        ; 01C9E8
	rts                                                ; 01C9F0
PatternCommand_breakmusic:
	move.w   #$3F,Snd_MusicRow                         ; 01C9F2
	rts                                                ; 01C9FA
PatternCommand_cmd7E:
	subq.w   #$1,d0                                    ; 01C9FC  $7E: jump to order position lo (after this row); lo = 0 ends a jingle
	tst.w    Snd_InJingle                              ; 01C9FE
	beq.b    PatternCommand_jumpmusic                  ; 01CA04
	move.w   #$3F,Snd_JingleRow                        ; 01CA06
	move.w   d0,Snd_JingleOrder                        ; 01CA0E
	rts                                                ; 01CA14
PatternCommand_jumpmusic:
	move.w   d0,Snd_MusicOrder                         ; 01CA16
	move.w   #$3F,Snd_MusicRow                         ; 01CA1C
	rts                                                ; 01CA24
PatternCommand_cmd7D:
	movea.l  Snd_Mailbox,a6                            ; 01CA26  $7D: speed = lo & $7F, bit 7 = upper voice bank (mailbox +$E / +$F)
	bsr.w    Snd_StopZ80                               ; 01CA2C
	tst.w    Snd_InJingle                              ; 01CA30
	beq.b    PatternCommand_musicspeed                 ; 01CA36
	clr.b    $F(a6)                                    ; 01CA38
	btst     #$7,d0                                    ; 01CA3C
	beq.b    PatternCommand_jinglespeed                ; 01CA40
	st.b     $F(a6)                                    ; 01CA42
PatternCommand_jinglespeed:
	bsr.w    Snd_StartZ80                              ; 01CA46
	andi.w   #$7F,d0                                   ; 01CA4A
	add.w    Snd_NTSCAdjust,d0                         ; 01CA4E
	move.w   d0,Snd_JingleSpeed                        ; 01CA54
	move.w   d0,Snd_JingleTick                         ; 01CA5A
	rts                                                ; 01CA60
PatternCommand_musicspeed:
	clr.b    $E(a6)                                    ; 01CA62
	btst     #$7,d0                                    ; 01CA66
	sf.b     $E(a6)                                    ; 01CA6A
	beq.b    PatternCommand_setspeed                   ; 01CA6E
	st.b     $E(a6)                                    ; 01CA70
PatternCommand_setspeed:
	bsr.w    Snd_StartZ80                              ; 01CA74
	andi.w   #$7F,d0                                   ; 01CA78
	add.w    Snd_NTSCAdjust,d0                         ; 01CA7C
	sub.w    Game_SpeedOffset,d0                       ; 01CA82
	move.w   d0,Snd_MusicSpeed                         ; 01CA88
PatternCommand_cmd7C:
	rts                                                ; 01CA8E
ClearMusicChans:
	clr.w    Snd_MusicChan+$02                         ; 01CA90  clear skip/RLE counters of the 6 music readers
	clr.w    Snd_MusicChan+$00                         ; 01CA96
	clr.w    Snd_MusicChan+$0E                         ; 01CA9C
	clr.w    Snd_MusicChan+$0C                         ; 01CAA2
	clr.w    Snd_MusicChan+$1A                         ; 01CAA8
	clr.w    Snd_MusicChan+$18                         ; 01CAAE
	clr.w    Snd_MusicChan+$26                         ; 01CAB4
	clr.w    Snd_MusicChan+$24                         ; 01CABA
	clr.w    Snd_MusicChan+$32                         ; 01CAC0
	clr.w    Snd_MusicChan+$30                         ; 01CAC6
	clr.w    Snd_MusicChan+$3E                         ; 01CACC
	clr.w    Snd_MusicChan+$3C                         ; 01CAD2
	rts                                                ; 01CAD8
ClearJingleChan:
	clr.w    Snd_JingleChan+$02                        ; 01CADA
	clr.w    Snd_JingleChan                            ; 01CAE0
	rts                                                ; 01CAE6
ClearSFXChan:
	clr.w    Snd_SFXChan+$02                           ; 01CAE8
	clr.w    Snd_SFXChan                               ; 01CAEE
	rts                                                ; 01CAF4

; --------------------------------------------------------------------------
;  SFX sequence (column 5: drum samples only)
; --------------------------------------------------------------------------
SFXSeq_Update:
	subq.w   #$1,d0                                    ; 01CAF6  d0 = SFX order position + 1
	lea.l    Snd_SFXChan,a5                            ; 01CAF8
	lea.l    Mod_Orders+5(pc),a0                       ; 01CAFE  order column 5
	tst.w    Mod_OrderFlag                             ; 01CB02
	beq.b    SFXSeq_Update_chk                         ; 01CB08
	lea.l    Mod_Orders+10(pc),a0                      ; 01CB0A
SFXSeq_Update_chk:
	addq.w   #$1,Snd_SFXTick                           ; 01CB0E
	move.w   Snd_SFXSpeed,d4                           ; 01CB14
	cmp.w    Snd_SFXTick,d4                            ; 01CB1A
	bcc.b    SFXSeq_Update_notyet                      ; 01CB20
	clr.w    Snd_SFXTick                               ; 01CB22
	bsr.w    SFXSeq_ReadRow                            ; 01CB28
	addq.w   #$1,Snd_SFXRow                            ; 01CB2C
	cmpi.w   #$40,Snd_SFXRow                           ; 01CB32
	bcs.b    SFXSeq_Update_exit                        ; 01CB3A
	clr.w    Snd_SFXChan+$02                           ; 01CB3C
	clr.w    Snd_SFXChan                               ; 01CB42
	bsr.b    ClearSFXChan                              ; 01CB48
	clr.w    Snd_SFXRow                                ; 01CB4A  end of pattern: next position, 0 = end
	addq.w   #$1,Snd_SFXOrder                          ; 01CB50
	tst.w    Snd_SFXOrder                              ; 01CB56
	bne.b    SFXSeq_Update_exit                        ; 01CB5C
	bsr.w    SFXSeq_End                                ; 01CB5E
	rts                                                ; 01CB62
SFXSeq_Update_exit:
	rts                                                ; 01CB64
SFXSeq_Update_notyet:
	rts                                                ; 01CB66
SFXSeq_End:
	move.w   #$1,d2                                    ; 01CB68  end of sequence: cut the sample (1 byte from Z80 address 0)
	move.w   #$0,d0                                    ; 01CB6C
	move.w   #$FF,d1                                   ; 01CB70
	bra.w    SendSample                                ; 01CB74
SFXSeq_ReadRow:
	tst.w    Mod_OrderFlag                             ; 01CB78
	beq.b    SFXSeq_ReadRow_bytes                      ; 01CB7E
	add.w    d0,d0                                     ; 01CB80
SFXSeq_ReadRow_bytes:
	mulu.w   #$6,d0                                    ; 01CB82
	adda.w   d0,a0                                     ; 01CB86
	moveq    #$0,d0                                    ; 01CB88
	tst.w    Mod_OrderFlag                             ; 01CB8A
	beq.b    SFXSeq_ReadRow_byte                       ; 01CB90
	move.w   (a0)+,d0                                  ; 01CB92
	bra.b    SFXSeq_ReadRow_got                        ; 01CB94
SFXSeq_ReadRow_byte:
	move.b   (a0)+,d0                                  ; 01CB96
SFXSeq_ReadRow_got:
	tst.w    $2(a5)                                    ; 01CB98
	beq.b    SFXSeq_ReadRow_fetch                      ; 01CB9C
	subq.w   #$1,$2(a5)                                ; 01CB9E
	addq.w   #$1,(a5)                                  ; 01CBA2
	rts                                                ; 01CBA4
SFXSeq_ReadRow_fetch:
	lsl.w    #$2,d0                                    ; 01CBA6
	lea.l    Mod_Patterns(pc),a1                       ; 01CBA8
	adda.w   d0,a1                                     ; 01CBAC
	movea.l  (a1),a1                                   ; 01CBAE
	move.w   Snd_SFXRow,d0                             ; 01CBB0
	sub.w    (a5),d0                                   ; 01CBB6
	add.w    d0,d0                                     ; 01CBB8
	adda.w   d0,a1                                     ; 01CBBA
	moveq    #$0,d0                                    ; 01CBBC
	moveq    #$0,d1                                    ; 01CBBE
	move.b   (a1)+,d0                                  ; 01CBC0
	move.b   (a1)+,d1                                  ; 01CBC2
	cmpi.b   #$FF,d1                                   ; 01CBC4
	bne.b    SFXSeq_ReadRow_decode                     ; 01CBC8
	tst.b    d0                                        ; 01CBCA
	beq.b    SFXSeq_ReadRow_empty                      ; 01CBCC
	move.w   d0,$2(a5)                                 ; 01CBCE
SFXSeq_ReadRow_empty:
	moveq    #$0,d0                                    ; 01CBD2
	moveq    #$0,d1                                    ; 01CBD4
SFXSeq_ReadRow_decode:
	move.b   d1,d2                                     ; 01CBD6  only N $6D-$74 (samples) and commands are used here
	lsr.b    #$1,d1                                    ; 01CBD8
	cmpi.b   #$7C,d1                                   ; 01CBDA
	bcc.b    SFXSeq_ReadRow_cmd                        ; 01CBDE
	subi.b   #$6D,d1                                   ; 01CBE0
	bcs.b    SFXSeq_ReadRow_exit                       ; 01CBE4
	cmpi.b   #$8,d1                                    ; 01CBE6
	bcc.b    SFXSeq_ReadRow_exit                       ; 01CBEA
	lea.l    Mod_Samples(pc),a1                        ; 01CBEC  module sample table
	andi.w   #$FF,d1                                   ; 01CBF0
	add.w    d1,d1                                     ; 01CBF4
	add.w    d1,d1                                     ; 01CBF6
	adda.w   d1,a1                                     ; 01CBF8
	move.w   d0,d1                                     ; 01CBFA  d1 = rate (cell lo byte)
	move.w   (a1),d0                                   ; 01CBFC
	ori.w    #$8000,d0                                 ; 01CBFE
	move.w   $2(a1),d2                                 ; 01CC02
	bsr.w    SendSample                                ; 01CC06
SFXSeq_ReadRow_exit:
	rts                                                ; 01CC0A
SFXSeq_ReadRow_cmd:
	cmpi.b   #$7C,d1                                   ; 01CC0C
	beq.w    SFXSeq_ReadRow_cmd7C                      ; 01CC10
	cmpi.b   #$7D,d1                                   ; 01CC14
	beq.b    SFXSeq_ReadRow_cmd7D                      ; 01CC18
	cmpi.b   #$7E,d1                                   ; 01CC1A
	beq.b    SFXSeq_ReadRow_cmd7E                      ; 01CC1E
	move.w   #$3F,Snd_SFXRow                           ; 01CC20
	rts                                                ; 01CC28
SFXSeq_ReadRow_cmd7E:
	subq.w   #$1,d0                                    ; 01CC2A  $7E: next position lo-1 ($7E 00 = end)
	move.w   #$3F,Snd_SFXRow                           ; 01CC2C
	move.w   d0,Snd_SFXOrder                           ; 01CC34
	rts                                                ; 01CC3A
SFXSeq_ReadRow_cmd7D:
	movea.l  Snd_Mailbox,a6                            ; 01CC3C  $7D: speed
	bsr.w    Snd_StopZ80                               ; 01CC42
	andi.w   #$7F,d0                                   ; 01CC46
	add.w    Snd_NTSCAdjust,d0                         ; 01CC4A
	move.w   d0,Snd_SFXSpeed                           ; 01CC50
	move.w   d0,Snd_SFXTick                            ; 01CC56
	rts                                                ; 01CC5C
SFXSeq_ReadRow_cmd7C:
	rts                                                ; 01CC5E
Snd_PlaySampleAddr:
	move.w   d1,Snd_PendRate                           ; 01CC60  d0 = Z80 address ($8000 | offset in bank 2), d1 = rate, d2 = length (no caller in the game)
	move.w   d0,Snd_PendAddr                           ; 01CC66
	move.w   d2,Snd_PendLen                            ; 01CC6C
	rts                                                ; 01CC72
SendPendingSample:
	clr.w    Snd_SFXOrder                              ; 01CC74  send a direct sample (nothing in this game sets Snd_PendRate)
	clr.w    Snd_SFXRow                                ; 01CC7A
	move.w   Snd_PendRate,d1                           ; 01CC80
	move.w   Snd_PendAddr,d0                           ; 01CC86
	move.w   Snd_PendLen,d2                            ; 01CC8C
	clr.w    Snd_PendRate                              ; 01CC92
SendSample:
	tst.w    Snd_Paused                                ; 01CC98  d0 = Z80 address, d1 = rate, d2 = length; not while paused
	bne.b    SendSample_exit                           ; 01CC9E
	movea.l  Snd_Mailbox,a6                            ; 01CCA0
	bsr.w    Snd_StopZ80                               ; 01CCA6
	move.b   d0,$10(a6)                                ; 01CCAA
	lsr.w    #$8,d0                                    ; 01CCAE
	move.b   d0,$11(a6)                                ; 01CCB0
	move.b   d1,$12(a6)                                ; 01CCB4
	move.b   d2,$14(a6)                                ; 01CCB8
	lsr.w    #$8,d2                                    ; 01CCBC
	move.b   d2,$15(a6)                                ; 01CCBE
	st.b     $16(a6)                                   ; 01CCC2  trigger (Z80 starts it from its wait loop)
	bsr.w    Snd_StartZ80                              ; 01CCC6
SendSample_exit:
	rts                                                ; 01CCCA
Z80_BootStub:
	dc.b     $F3,$AF,$32,$00,$10,$11,$06,$09,$7B       ; 01CCCC  27 bytes: di / xor a / ld ($1000),a / ld de,<bank> / 9x bank bit / ld a,$FF / ld ($1000),a / jr $
	dc.b     $E6,$01,$32,$00,$60,$CB,$1A,$CB,$1B       ; 01CCD5
	dc.b     $10,$F4,$3E,$FF,$32,$00,$10,$18,$FE       ; 01CCDE
	dc.b     $00                                       ; 01CCE7
Z80_ResetHold:
	move.w   #$100,($A11100).l                         ; 01CCE8
	move.w   #$0,($A11200).l                           ; 01CCF0
	moveq    #$9,d0                                    ; 01CCF8
Z80_ResetHold_dly:
	nop                                                ; 01CCFA
	dbra     d0,Z80_ResetHold_dly                      ; 01CCFC
	move.w   #$100,($A11200).l                         ; 01CD00
	rts                                                ; 01CD08
Z80_LoadDriver:
	bsr.b    Z80_ResetHold                             ; 01CD0A  boot stub to Z80 $0000
	lea.l    ($A00000).l,a0                            ; 01CD0C
	lea.l    Z80_BootStub(pc),a1                       ; 01CD12
	moveq    #$5,d7                                    ; 01CD16
Z80_LoadDriver_stub1:
	move.b   (a1)+,(a0)+                               ; 01CD18
	dbra     d7,Z80_LoadDriver_stub1                   ; 01CD1A
	move.w   #$2,d0                                    ; 01CD1E  bank 2: $010000-$017FFF holds all eight samples
	move.b   d0,(a0)+                                  ; 01CD22
	lsr.w    #$8,d0                                    ; 01CD24
	move.b   d0,(a0)+                                  ; 01CD26
	moveq    #$14,d7                                   ; 01CD28
Z80_LoadDriver_stub2:
	move.b   (a1)+,(a0)+                               ; 01CD2A
	dbra     d7,Z80_LoadDriver_stub2                   ; 01CD2C
	bsr.w    Z80_ResetRelease                          ; 01CD30
Z80_LoadDriver_waitalive:
	moveq    #$63,d7                                   ; 01CD34  wait until the stub has written $FF to $1000
Z80_LoadDriver_dly:
	dbra     d7,Z80_LoadDriver_dly                     ; 01CD36
	move.w   #$100,($A11100).l                         ; 01CD3A
Z80_LoadDriver_waitbus:
	btst.b   #$0,($A11100).l                           ; 01CD42
	bne.b    Z80_LoadDriver_waitbus                    ; 01CD4A
	move.b   ($A01000).l,d0                            ; 01CD4C
	bne.b    Z80_LoadDriver_upload                     ; 01CD52
	move.w   #$0,($A11100).l                           ; 01CD54
	bra.b    Z80_LoadDriver_waitalive                  ; 01CD5C
Z80_LoadDriver_upload:
	bsr.b    Z80_ResetHold                             ; 01CD5E  upload $1400 bytes to Z80 $0C00, then patch $0000 = di / jp $0C00
	lea.l    Z80_Driver(pc),a0                         ; 01CD60
	lea.l    ($A00C00).l,a1                            ; 01CD64
	move.w   #$13FF,d7                                 ; 01CD6A
Z80_LoadDriver_copy:
	move.b   (a0)+,(a1)+                               ; 01CD6E
	dbra     d7,Z80_LoadDriver_copy                    ; 01CD70
	move.b   #$F3,($A00000).l                          ; 01CD74
	move.b   #$C3,($A00001).l                          ; 01CD7C
	move.b   #$0,($A00002).l                           ; 01CD84
	move.b   #$C,($A00003).l                           ; 01CD8C
	bsr.b    Z80_ResetRelease                          ; 01CD94
	sf.b     Snd_Z80Held                               ; 01CD96
	rts                                                ; 01CD9C
Z80_ResetRelease:
	move.w   #$0,($A11200).l                           ; 01CD9E
	move.w   #$0,($A11100).l                           ; 01CDA6
	moveq    #$9,d0                                    ; 01CDAE
Z80_ResetRelease_dly:
	nop                                                ; 01CDB0
	dbra     d0,Z80_ResetRelease_dly                   ; 01CDB2
	move.w   #$100,($A11200).l                         ; 01CDB6
	rts                                                ; 01CDBE
Snd_StopZ80:
	move.b   #$1,($A11100).l                           ; 01CDC0  request the bus and wait for it (interrupts off meanwhile)
	move.l   d0,-(a7)                                  ; 01CDC8
Snd_StopZ80_wait:
	move.b   ($A11100).l,d0                            ; 01CDCA
	andi.b   #$1,d0                                    ; 01CDD0
	bne.b    Snd_StopZ80_wait                          ; 01CDD4
	st.b     Snd_Z80Held                               ; 01CDD6
	move.l   (a7)+,d0                                  ; 01CDDC
	rts                                                ; 01CDDE
Snd_StartZ80:
	move.b   #$0,($A11100).l                           ; 01CDE0
	sf.b     Snd_Z80Held                               ; 01CDE8
	rts                                                ; 01CDEE
Z80_UploadBanks:
	lea.l    Mod_Voices(pc),a1                         ; 01CDF0  $800 bytes of voices -> Z80 $0400 (64 voices)
	bsr.w    Z80_WaitIdle                              ; 01CDF4
	lea.l    ($A00400).l,a0                            ; 01CDF8
	move.w   #$7FF,d7                                  ; 01CDFE
Z80_UploadBanks_voices:
	move.b   (a1)+,(a0)+                               ; 01CE02
	dbra     d7,Z80_UploadBanks_voices                 ; 01CE04
	move.b   #$2,(a6)                                  ; 01CE08  command 2 (reset)
	lea.l    $18(a6),a6                                ; 01CE0C
	lea.l    Mod_Samples(pc),a0                        ; 01CE10  module sample table -> mailbox +$18
	move.w   #$1F,d7                                   ; 01CE14
Z80_UploadBanks_samples:
	move.b   (a0)+,(a6)+                               ; 01CE18
	dbra     d7,Z80_UploadBanks_samples                ; 01CE1A
	bsr.b    Snd_StartZ80                              ; 01CE1E
	rts                                                ; 01CE20
Z80_CmdReset:
	bsr.w    Z80_WaitIdle                              ; 01CE22
	move.b   #$2,(a6)                                  ; 01CE26
	bsr.b    Snd_StartZ80                              ; 01CE2A
	rts                                                ; 01CE2C
Z80_CmdSilence:
	bsr.w    Z80_WaitIdle                              ; 01CE2E
	move.b   #$4,(a6)                                  ; 01CE32
	bsr.b    Snd_StartZ80                              ; 01CE36
	rts                                                ; 01CE38
Z80_SendTick:
	bsr.w    Z80_WaitIdle                              ; 01CE3A  per-frame tick (command 1), always sent
	move.b   #$1,(a6)                                  ; 01CE3E
	bsr.b    Snd_StartZ80                              ; 01CE42
	rts                                                ; 01CE44
Z80_SendRow:
	bsr.w    Z80_WaitIdle                              ; 01CE46  new row (command $0A), always sent
	lea.l    $2(a6),a5                                 ; 01CE4A
	move.w   #$5,d7                                    ; 01CE4E
	lea.l    Snd_MusicChan+$00,a0                      ; 01CE52
Z80_SendRow_copy:
	move.b   $4(a0),(a5)+                              ; 01CE58  6 cells -> mailbox +2
	move.b   $5(a0),(a5)+                              ; 01CE5C
	lea.l    $C(a0),a0                                 ; 01CE60
	dbra     d7,Z80_SendRow_copy                       ; 01CE64
	move.b   #$A,(a6)                                  ; 01CE68
	bsr.w    Snd_StartZ80                              ; 01CE6C
	rts                                                ; 01CE70
Z80_WaitIdle:
	movea.l  Snd_Mailbox,a6                            ; 01CE72  hold the bus until the Z80 has taken the last command; a6 = mailbox
Z80_WaitIdle_wait:
	bsr.w    Snd_StopZ80                               ; 01CE78
	move.b   (a6),d0                                   ; 01CE7C
	beq.b    Z80_WaitIdle_exit                         ; 01CE7E
	bsr.w    Snd_StartZ80                              ; 01CE80
	nop                                                ; 01CE84
	nop                                                ; 01CE86
	nop                                                ; 01CE88
	nop                                                ; 01CE8A
	nop                                                ; 01CE8C
	nop                                                ; 01CE8E
	nop                                                ; 01CE90
	nop                                                ; 01CE92
	nop                                                ; 01CE94
	nop                                                ; 01CE96
	nop                                                ; 01CE98
	bra.b    Z80_WaitIdle_wait                         ; 01CE9A
	dc.b     $61,$00,$FF,$22                           ; 01CE9C  (dead code: bsr.w Snd_StopZ80)
Z80_WaitIdle_exit:
	rts                                                ; 01CEA0
Z80_Driver:
	incbin  "ChuckRock_Z80.bin"                     ; 01CEA2  $1400 bytes uploaded to Z80 $0C00, see Kris_Z80_rev1_*.asm
