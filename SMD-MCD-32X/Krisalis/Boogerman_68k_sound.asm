; Generated from the ROM by tools/mdis.py (capstone) + m68k_v3.py.
; Syntax: asm68k-style; RAM and module addresses as equates.

Snd_Mailbox              equ  $FF051A   ; long: $A00000 + Z80 mailbox address (read from Z80 $0004)
Snd_IsNTSC               equ  $FF0520   ; 1 = 60 Hz console: every 6th frame is skipped
Snd_NTSCSkip             equ  $FF0522   ; frame counter 0-5 for the NTSC skip
Snd_PauseReq             equ  $FF0524   ; 1 = pause, 2 = resume (handled by the next update)
Snd_Paused               equ  $FF0526   ; $FF while paused
Snd_MusicReq             equ  $FF0528   ; order position + 1 requested by Snd_PlayMusic
Snd_MusicTick            equ  $FF052A   ; frames since the last music row
Snd_MusicOrder           equ  $FF052C   ; current order position (song)
Snd_MusicRow             equ  $FF052E   ; row 0-63 in the current patterns
Snd_SFXOrder             equ  $FF0530   ; order position + 1 of the SFX sequence (0 = off)
Snd_SFXRow               equ  $FF0532   ; row of the SFX sequence
Snd_SFXTick              equ  $FF0534   ; frames since the last SFX-sequence row
Snd_SFXSpeed             equ  $FF0536   ; SFX-sequence speed
Snd_PendRate             equ  $FF0538   ; pending direct sample: rate (non-zero = pending)
Snd_PendLen              equ  $FF053A   ; pending direct sample: length
Snd_PendAddr             equ  $FF053C   ; pending direct sample: $8000 | (addr & $7FFF)
Snd_PendBank             equ  $FF053E   ; pending direct sample: ROM bank (addr >> 15)
Snd_JingleOrder          equ  $FF0540   ; order position of the jingle
Snd_JingleRow            equ  $FF0542   ; row of the jingle
Snd_FetchRow             equ  $FF0544   ; row used by ReadCell
Snd_MusicSpeed           equ  $FF0546   ; music speed: a row every speed+1 frames
Snd_Busy                 equ  $FF0548   ; $FF while Snd_Update runs (or while paused)
Snd_InJingle             equ  $FF054A   ; $FF while the jingle column is being read (commands act on the jingle)
Snd_JingleActive         equ  $FF054C   ; $FF while a jingle plays
Snd_JingleTick           equ  $FF054E   ; frames since the last jingle row
Snd_JingleSpeed          equ  $FF0550   ; jingle speed
Snd_JingleReq            equ  $FF0552   ; order position + 1 requested by Snd_PlayJingle
Snd_MusicChan            equ  $FF0554   ; 6 x 12 bytes, music channel readers
Snd_JingleChan           equ  $FF059C   ; 12 bytes, jingle reader (column 4 = FM5)
Snd_SFXChan              equ  $FF05A8   ; 12 bytes, SFX-sequence reader (column 5 = FM6/DAC)
Snd_MusicVol             equ  $FF05B4   ; music attenuation (byte)
Snd_JingleVol            equ  $FF05B6   ; jingle attenuation (byte)
Snd_Z80Held              equ  $FF05B8   ; $FF while the 68k holds the Z80 bus
Snd_StopJingle           equ  $FF05BA   ; $FF: stop the jingle (set by Snd_PlayMusic)
Snd_SavedJingle          equ  $FF05BC   ; mailbox +1 saved over a pause
Snd_SFXBusy              equ  $FF05BE   ; copy of the Z80 SFX-busy flag
Mod_Samples              equ  $028000   ; module: 8 x (offset.w, length.w)
Mod_OrderFlag            equ  $028020   ; module: $FFFF = word order entries, 0 = byte
Mod_Patterns             equ  $028022   ; module: pattern pointer table
Mod_Orders               equ  $0286CA   ; module: order list (6 words per row)
Mod_Voices               equ  $02F85A   ; voice bank (64 x 32 bytes)

	org	$98000


; ==========================================================================
;  Krisalis sound module (Shaun Hollingworth) -- 68k side, revision 3
;  Boogerman (E):  code $098000-$098D53, Z80 driver $098D54,
;                  music module $028000 (8 samples in bank 4 = $020000-$027FFF),
;                  voices $02F85A, extra samples $038000-$096A07.
;  The 68k is the sequencer: once per frame Snd_Update advances the music,
;  the jingle (one column played on FM5) and the SFX sequence (column 5,
;  drum samples only) and sends either a whole row of 6 cells (command $0A)
;  or a tick (command 1) to the Z80 mailbox.
;  Call: moveq #fn,d7 / jsr Sound_Dispatch.
; ==========================================================================
Sound_Dispatch:
	lsl.w    #$2,d7                                    ; 098000  d7 = function number (0-19), other registers = parameters
	jmp      Sound_JumpTable(pc,d7.w)                  ; 098002
Sound_JumpTable:
	bra.w    Snd_Update                                ; 098006   0 Snd_Update
	bra.w    Snd_PlayMusic                             ; 09800A   1 Snd_PlayMusic
	bra.w    Snd_PlayJingle                            ; 09800E   2 Snd_PlayJingle
	bra.w    Snd_PlaySFXSeq                            ; 098012   3 Snd_PlaySFXSeq
	bra.w    Snd_Pause                                 ; 098016   4 Snd_Pause
	bra.w    Snd_Resume                                ; 09801A   5 Snd_Resume
	bra.w    Snd_PlaySampleAddr                        ; 09801E   6 Snd_PlaySampleAddr
	bra.w    Snd_IsJinglePlaying                       ; 098022   7 Snd_IsJinglePlaying
	bra.w    Snd_IsSFXSamplePlaying                    ; 098026   8 Snd_IsSFXSamplePlaying
	bra.w    Snd_MusicVolume                           ; 09802A   9 Snd_MusicVolume
	bra.w    Snd_JingleVolume                          ; 09802E  10 Snd_JingleVolume
	bra.w    Snd_GetMusicPos                           ; 098032  11 Snd_GetMusicPos
	bra.w    Snd_GetJinglePos                          ; 098036  12 Snd_GetJinglePos
	bra.w    Snd_GetSFXPos                             ; 09803A  13 Snd_GetSFXPos
	bra.w    Snd_StopZ80                               ; 09803E  14 Snd_StopZ80
	bra.w    Snd_StartZ80                              ; 098042  15 Snd_StartZ80
	bra.w    Snd_SetJinglePan                          ; 098046  16 Snd_SetJinglePan
	bra.w    Snd_SetSFXPan                             ; 09804A  17 Snd_SetSFXPan
	bra.w    Snd_Init                                  ; 09804E  18 Snd_Init
	bra.w    Snd_PlayExtSampleJ                        ; 098052  19 Snd_PlayExtSample

; --------------------------------------------------------------------------
;  Small API functions
; --------------------------------------------------------------------------
Snd_GetMusicPos:
	move.w   Snd_MusicOrder,d0                         ; 098056  out: d0 = order position, d1 = row
	move.w   Snd_MusicRow,d1                           ; 09805C
	rts                                                ; 098062
Snd_GetJinglePos:
	move.w   Snd_JingleOrder,d0                        ; 098064
	move.w   Snd_JingleRow,d1                          ; 09806A
	rts                                                ; 098070
Snd_GetSFXPos:
	move.w   Snd_SFXOrder,d0                           ; 098072
	move.w   Snd_SFXRow,d1                             ; 098078
	rts                                                ; 09807E
Snd_MusicVolume:
	cmpi.b   #$FF,d0                                   ; 098080  d0 = attenuation, $FF = read back
	beq.w    Snd_MusicVolume_get                       ; 098084
	move.b   d0,Snd_MusicVol                           ; 098088
	rts                                                ; 09808E
Snd_MusicVolume_get:
	move.b   Snd_MusicVol,d0                           ; 098090
	rts                                                ; 098096
Snd_JingleVolume:
	cmpi.b   #$FF,d0                                   ; 098098
	beq.w    Snd_JingleVolume_get                      ; 09809C
	move.b   d0,Snd_JingleVol                          ; 0980A0
	rts                                                ; 0980A6
Snd_JingleVolume_get:
	move.b   Snd_JingleVol,d0                          ; 0980A8
	rts                                                ; 0980AE
Snd_IsJinglePlaying:
	tst.w    Snd_JingleActive                          ; 0980B0  Z flag clear while a jingle plays
	rts                                                ; 0980B6
Snd_IsSFXSamplePlaying:
	tst.w    Snd_SFXBusy                               ; 0980B8  Z flag clear while an SFX sample plays
	rts                                                ; 0980BE
Snd_Pause:
	move.w   #$1,Snd_PauseReq                          ; 0980C0  request pause; Snd_Busy keeps the update idle until Snd_Resume
	st.b     Snd_Paused                                ; 0980C8
	rts                                                ; 0980CE
Snd_Resume:
	tst.w    Snd_Busy                                  ; 0980D0  only if paused: request resume
	beq.b    Snd_Resume_exit                           ; 0980D6
	move.w   #$2,Snd_PauseReq                          ; 0980D8
	sf.b     Snd_Busy                                  ; 0980E0
	sf.b     Snd_Paused                                ; 0980E6
Snd_Resume_exit:
	rts                                                ; 0980EC
Snd_Init:
	move.w   sr,-(a7)                                  ; 0980EE  clear the module RAM
	move.w   #$2700,sr                                 ; 0980F0
	lea.l    Snd_Mailbox,a0                            ; 0980F4
	lea.l    ($FF05C0).l,a1                            ; 0980FA
	move.w   #$A5,d7                                   ; 098100
Snd_Init_clr:
	clr.b    (a0)+                                     ; 098104
	dbra     d7,Snd_Init_clr                           ; 098106
	nop                                                ; 09810A
	bsr.w    Z80_LoadDriver                            ; 09810C  reset Z80, run the boot stub, upload the driver
	move.w   #$400,d7                                  ; 098110
Snd_Init_delay:
	dbra     d7,Snd_Init_delay                         ; 098114
	bsr.w    Snd_StopZ80                               ; 098118
	clr.w    Snd_IsNTSC                                ; 09811C  PAL/NTSC: bit 6 of the version register = 1 on PAL
	btst.b   #$6,($A10001).l                           ; 098122
	bne.b    Snd_Init_pal                              ; 09812A
	addq.w   #$1,Snd_IsNTSC                            ; 09812C
Snd_Init_pal:
	moveq    #$0,d0                                    ; 098132  read the mailbox pointer from Z80 $0004/$0005
	move.b   ($A00005).l,d0                            ; 098134
	rol.l    #$8,d0                                    ; 09813A
	move.b   ($A00004).l,d0                            ; 09813C
	addi.l   #$A00000,d0                               ; 098142
	move.l   d0,Snd_Mailbox                            ; 098148
	bsr.w    Snd_StartZ80                              ; 09814E  release the Z80
	bsr.w    Z80_UploadBanks                           ; 098152  upload the voice bank and sample table
	move.w   (a7)+,sr                                  ; 098156
	rts                                                ; 098158
Unused_9815A:
	dc.w     $51F9,$00FF,$0548,$4279,$00FF,$0524       ; 09815A  (orphaned code, never executed)
Snd_PlayExtSampleJ:
	jmp      Snd_PlayExtSample                         ; 098166
Snd_PlayMusic:
	addq.w   #$1,d0                                    ; 09816C  d0 = order position (0 / 1 = silence); also stops a jingle
	move.w   d0,Snd_MusicReq                           ; 09816E
	st.b     Snd_StopJingle                            ; 098174
	sf.b     Snd_MusicChan+$38                         ; 09817A
	clr.w    Snd_PauseReq                              ; 098180
	clr.w    Snd_Paused                                ; 098186
	sf.b     Snd_Busy                                  ; 09818C
	rts                                                ; 098192
Snd_PlayJingle:
	tst.w    Snd_Paused                                ; 098194  d0 = order position of the jingle (column 4 is played on FM5)
	bne.b    Snd_PlayJingle_exit                       ; 09819A
	addq.w   #$1,d0                                    ; 09819C
	move.w   d0,Snd_JingleReq                          ; 09819E
	sf.b     Snd_Busy                                  ; 0981A4
Snd_PlayJingle_exit:
	rts                                                ; 0981AA
Snd_PlaySFXSeq:
	addq.w   #$1,d0                                    ; 0981AC  d0 = order position of the SFX sequence (column 5 = drum samples)
	move.w   d0,Snd_SFXOrder                           ; 0981AE
	clr.w    Snd_SFXRow                                ; 0981B4
	bsr.w    ClearSFXChan                              ; 0981BA
	move.w   #$1,Snd_SFXSpeed                          ; 0981BE  speed 1: a row every 2 frames
	clr.w    Snd_PendRate                              ; 0981C6
	rts                                                ; 0981CC

; --------------------------------------------------------------------------
;  Snd_Update (function 0): call once per frame
; --------------------------------------------------------------------------
Snd_Update:
	btst.b   #$0,($A11100).l                           ; 0981CE  once per frame (VBlank). Works whether or not the caller holds the Z80 bus
	move.w   sr,-(a7)                                  ; 0981D6
	bne.b    Snd_Update_held                           ; 0981D8
	move.w   #$0,($A11100).l                           ; 0981DA
Snd_Update_held:
	bsr.b    Snd_Frame                                 ; 0981E2
	move.w   (a7)+,sr                                  ; 0981E4
	bne.b    Snd_Update_exit                           ; 0981E6
	move.w   #$100,($A11100).l                         ; 0981E8
Snd_Update_wait:
	btst.b   #$0,($A11100).l                           ; 0981F0
	bne.b    Snd_Update_wait                           ; 0981F8
Snd_Update_exit:
	rts                                                ; 0981FA
Snd_Frame:
	tst.w    Snd_IsNTSC                                ; 0981FC  60 Hz: skip every 6th frame so the tempo matches 50 Hz
	beq.b    Snd_Frame_run                             ; 098202
	addq.w   #$1,Snd_NTSCSkip                          ; 098204
	cmpi.w   #$6,Snd_NTSCSkip                          ; 09820A
	bcs.b    Snd_Frame_run                             ; 098212
	clr.w    Snd_NTSCSkip                              ; 098214
	rts                                                ; 09821A
Snd_Frame_run:
	tst.b    Snd_Busy                                  ; 09821C  re-entered or paused?
	beq.b    Snd_Frame_chkpause                        ; 098222
	rts                                                ; 098224
Snd_Frame_chkpause:
	tst.w    Snd_PauseReq                              ; 098226  pause/resume request?
	beq.w    Snd_Frame_play                            ; 09822C
	movem.l  d0-d7/a0-a6,-(a7)                         ; 098230
	move.w   Snd_PauseReq,d0                           ; 098234
	subq.w   #$1,d0                                    ; 09823A
	beq.b    Snd_Frame_pause                           ; 09823C
	bsr.w    Z80_WaitIdle                              ; 09823E  resume: restart voices, restore the jingle state
	move.b   #$7,$0(a6)                                ; 098242
	move.w   Snd_SavedJingle,d0                        ; 098248
	move.b   d0,$1(a6)                                 ; 09824E
	bsr.w    Snd_StartZ80                              ; 098252
	sf.b     Snd_Busy                                  ; 098256
	clr.w    Snd_PauseReq                              ; 09825C
	movem.l  (a7)+,d0-d7/a0-a6                         ; 098262
	rts                                                ; 098266
Snd_Frame_pause:
	st.b     Snd_Busy                                  ; 098268  pause: save jingle state, silence, stop the SFX sequence
	clr.w    Snd_PauseReq                              ; 09826E
	bsr.w    Z80_WaitIdle                              ; 098274
	move.b   $1(a6),d0                                 ; 098278
	move.w   d0,Snd_SavedJingle                        ; 09827C
	clr.b    $1(a6)                                    ; 098282
	bsr.w    Z80_CmdSilence                            ; 098286
	bsr.w    Snd_StartZ80                              ; 09828A
	clr.w    Snd_SFXOrder                              ; 09828E
	bsr.w    Snd_StartZ80                              ; 098294
	movem.l  (a7)+,d0-d7/a0-a6                         ; 098298
	rts                                                ; 09829C
Snd_Frame_play:
	movem.l  d0-d7/a0-a6,-(a7)                         ; 09829E  normal frame
	st.b     Snd_Busy                                  ; 0982A2
	move.w   Snd_JingleReq,d0                          ; 0982A8  jingle requested?
	beq.b    Snd_Frame_music                           ; 0982AE
	subq.w   #$1,d0                                    ; 0982B0
	cmpi.w   #$FF,d0                                   ; 0982B2  (position $FF is treated as 0)
	bne.b    Snd_Frame_jingle                          ; 0982B6
	moveq    #$0,d0                                    ; 0982B8
Snd_Frame_jingle:
	move.w   d0,Snd_JingleOrder                        ; 0982BA
	clr.w    Snd_JingleReq                             ; 0982C0
	clr.w    Snd_JingleSpeed                           ; 0982C6
	clr.w    Snd_JingleRow                             ; 0982CC
	clr.w    Snd_JingleTick                            ; 0982D2
	bsr.w    ClearJingleChan                           ; 0982D8  clear the jingle reader
	st.b     Snd_JingleActive                          ; 0982DC
	movea.l  Snd_Mailbox,a6                            ; 0982E2
	bsr.w    Snd_StopZ80                               ; 0982E8  mailbox: jingle volume, jingle on, jingle voice bank 0
	move.b   Snd_JingleVol,$3C(a6)                     ; 0982EC
	st.b     $1(a6)                                    ; 0982F4
	sf.b     $F(a6)                                    ; 0982F8
	bsr.w    Snd_StartZ80                              ; 0982FC
Snd_Frame_music:
	move.w   Snd_MusicReq,d0                           ; 098300  music requested?
	beq.b    Snd_Frame_sfxseq                          ; 098306
	subq.w   #$1,d0                                    ; 098308
	move.w   d0,Snd_MusicOrder                         ; 09830A
	clr.w    Snd_MusicRow                              ; 098310
	move.w   #$6,Snd_MusicSpeed                        ; 098316  default speed 6 (7 frames per row)
	bsr.w    ClearMusicChans                           ; 09831E
	movea.l  Snd_Mailbox,a6                            ; 098322
	bsr.w    Snd_StopZ80                               ; 098328
	sf.b     $1(a6)                                    ; 09832C  mailbox: jingle off, music volume 0
	sf.b     Snd_MusicChan+$38                         ; 098330
	sf.b     $3A(a6)                                   ; 098336
	bsr.w    Snd_StartZ80                              ; 09833A
	bsr.w    Z80_CmdReset                              ; 09833E  Z80: reset channel state, silence
	bsr.w    Z80_CmdSilence                            ; 098342
	bsr.w    ClearMusicChans                           ; 098346
	clr.w    Snd_MusicReq                              ; 09834A  mailbox: music voice bank 0
	bsr.w    Snd_StopZ80                               ; 098350
	sf.b     $E(a6)                                    ; 098354
	bsr.w    Snd_StartZ80                              ; 098358
	bra.b    Snd_Frame_exit                            ; 09835C
Snd_Frame_sfxseq:
	move.w   Snd_SFXOrder,d0                           ; 09835E  SFX sequence running?
	beq.b    Snd_Frame_pending                         ; 098364
	bsr.w    SFXSeq_Update                             ; 098366
Snd_Frame_pending:
	tst.w    Snd_PendRate                              ; 09836A  direct sample waiting?
	beq.b    Snd_Frame_musictick                       ; 098370
	bsr.w    SendPendingSample                         ; 098372
Snd_Frame_musictick:
	addq.w   #$1,Snd_MusicTick                         ; 098376  music tick
	move.w   Snd_MusicSpeed,d0                         ; 09837C
	cmp.w    Snd_MusicTick,d0                          ; 098382
	bcc.b    Snd_Frame_between                         ; 098388
	clr.w    Snd_MusicTick                             ; 09838A
	bsr.w    Music_ReadRow                             ; 098390  read 6 cells
	addq.w   #$1,Snd_MusicRow                          ; 098394
	cmpi.w   #$40,Snd_MusicRow                         ; 09839A
	bcs.b    Snd_Frame_rowdone                         ; 0983A2
	clr.w    Snd_MusicRow                              ; 0983A4  end of pattern: next order position
	addq.w   #$1,Snd_MusicOrder                        ; 0983AA
	bsr.w    ClearMusicChans                           ; 0983B0
Snd_Frame_rowdone:
	bsr.w    Jingle_OnRow                              ; 0983B4  jingle row (overrides FM5) and send the row
	bsr.w    Z80_SendRow                               ; 0983B8
	bra.b    Snd_Frame_exit                            ; 0983BC
Snd_Frame_between:
	bsr.w    Jingle_OffRow                             ; 0983BE  no music row: jingle-only row or a tick
	beq.b    Snd_Frame_tickonly                        ; 0983C2
	bsr.w    Z80_SendRow                               ; 0983C4
	bra.b    Snd_Frame_exit                            ; 0983C8
Snd_Frame_tickonly:
	bsr.w    Z80_SendTick                              ; 0983CA
Snd_Frame_exit:
	sf.b     Snd_Busy                                  ; 0983CE
	movem.l  (a7)+,d0-d7/a0-a6                         ; 0983D4
	rts                                                ; 0983D8

; --------------------------------------------------------------------------
;  Jingle (column 4 of the order list, played on FM5)
; --------------------------------------------------------------------------
Jingle_OnRow:
	bsr.b    Jingle_Step                               ; 0983DA  jingle row read? then its cell replaces the FM5 cell
	bne.b    Jingle_CopyCell                           ; 0983DC
	rts                                                ; 0983DE
Jingle_CopyCell:
	move.w   Snd_JingleChan+$04,Snd_MusicChan+$34      ; 0983E0
	moveq    #$1,d0                                    ; 0983EA
	rts                                                ; 0983EC
Jingle_OffRow:
	bsr.b    Jingle_Step                               ; 0983EE  jingle-only row: clear the other cells so nothing re-triggers
	beq.b    Jingle_OffRow_none                        ; 0983F0
	clr.w    Snd_MusicChan+$04                         ; 0983F2
	clr.w    Snd_MusicChan+$10                         ; 0983F8
	clr.w    Snd_MusicChan+$1C                         ; 0983FE
	clr.w    Snd_MusicChan+$28                         ; 098404
	clr.w    Snd_MusicChan+$40                         ; 09840A
	bra.w    Jingle_CopyCell                           ; 098410
Jingle_OffRow_none:
	rts                                                ; 098414
Jingle_Step:
	lea.l    Snd_JingleChan,a5                         ; 098416  a5 = jingle reader, a3 = music reader of FM5
	lea.l    Snd_MusicChan+$30,a3                      ; 09841C
	tst.w    Snd_StopJingle                            ; 098422  stop requested?
	bne.w    Jingle_Step_stop                          ; 098428
	tst.w    Snd_JingleActive                          ; 09842C
	beq.w    Jingle_Step_exit                          ; 098432
	clr.w    $4(a5)                                    ; 098436  clear the jingle cell; clear the FM5 music cell unless it is a command
	move.b   $5(a3),d1                                 ; 09843A
	lsr.b    #$1,d1                                    ; 09843E
	cmpi.b   #$7C,d1                                   ; 098440
	bcc.b    Jingle_Step_active                        ; 098444
	clr.w    $4(a3)                                    ; 098446
Jingle_Step_active:
	st.b     Snd_InJingle                              ; 09844A
	st.b     $A(a3)                                    ; 098450  mute the music reader of FM5 (its commands still run)
	move.w   Snd_JingleOrder,d0                        ; 098454  order column 4
	move.w   Snd_JingleRow,Snd_FetchRow                ; 09845A
	lea.l    Mod_Orders+4,a0                           ; 098464
	tst.w    Mod_OrderFlag                             ; 09846A
	beq.b    Jingle_Step_chk                           ; 098470
	lea.l    Mod_Orders+8,a0                           ; 098472
Jingle_Step_chk:
	move.w   #$0,d7                                    ; 098478
	addq.w   #$1,Snd_JingleTick                        ; 09847C
	move.w   Snd_JingleSpeed,d4                        ; 098482
	cmp.w    Snd_JingleTick,d4                         ; 098488
	bcc.b    Jingle_Step_norow                         ; 09848E
	clr.w    Snd_JingleTick                            ; 098490
	bsr.w    ReadOrderRow                              ; 098496
	addq.w   #$1,Snd_JingleRow                         ; 09849A
	cmpi.w   #$40,Snd_JingleRow                        ; 0984A0
	bcs.b    Jingle_Step_row                           ; 0984A8
	bsr.w    ClearJingleChan                           ; 0984AA  end of pattern
	clr.w    Snd_JingleRow                             ; 0984AE
	addq.w   #$1,Snd_JingleOrder                       ; 0984B4
	tst.w    Snd_JingleOrder                           ; 0984BA  wrapped to 0 ($7E 00): end of jingle, force the FM5 instrument on the next music note
	bne.b    Jingle_Step_row                           ; 0984C0
	st.b     $8(a3)                                    ; 0984C2
Jingle_Step_stop:
	sf.b     Snd_StopJingle                            ; 0984C6  end of jingle
	sf.b     $A(a3)                                    ; 0984CC
	clr.w    Snd_JingleActive                          ; 0984D0
	bsr.w    Snd_StopZ80                               ; 0984D6
	movea.l  Snd_Mailbox,a6                            ; 0984DA
	sf.b     $1(a6)                                    ; 0984E0
	bsr.w    Snd_StartZ80                              ; 0984E4
	moveq    #$0,d0                                    ; 0984E8
	sf.b     Snd_InJingle                              ; 0984EA
	rts                                                ; 0984F0
Jingle_Step_row:
	sf.b     Snd_InJingle                              ; 0984F2
	moveq    #$1,d0                                    ; 0984F8
	rts                                                ; 0984FA
Jingle_Step_norow:
	sf.b     Snd_InJingle                              ; 0984FC
	moveq    #$0,d0                                    ; 098502
Jingle_Step_exit:
	rts                                                ; 098504

; --------------------------------------------------------------------------
;  Pattern reading.  Reader (a5, 12 bytes):
;    +0 rows skipped by RLE   +2 empty rows left   +4/5 cell to send (lo,hi)
;    +6 last instrument*8     +8 force instrument  +A muted (FM5 during a jingle)
; --------------------------------------------------------------------------
Music_ReadRow:
	move.w   Snd_MusicOrder,d0                         ; 098506  music: all 6 columns of the order row
	move.w   Snd_MusicRow,Snd_FetchRow                 ; 09850C
	lea.l    Snd_MusicChan,a5                          ; 098516
	move.w   #$5,d7                                    ; 09851C
	lea.l    Mod_Orders,a0                             ; 098520
ReadOrderRow:
	tst.w    Mod_OrderFlag                             ; 098526  d0 = order position, a0 = order column, d7 = columns-1, a5 = readers
	beq.b    ReadOrderRow_bytes                        ; 09852C  word or byte order entries (module flag at +$20)
	add.w    d0,d0                                     ; 09852E
ReadOrderRow_bytes:
	andi.l   #$FFFF,d0                                 ; 098530
	mulu.w   #$6,d0                                    ; 098536  6 entries per order row
	adda.w   d0,a0                                     ; 09853A
ReadOrderRow_chan:
	moveq    #$0,d0                                    ; 09853C
	tst.w    Mod_OrderFlag                             ; 09853E
	beq.b    ReadOrderRow_byte                         ; 098544
	move.w   (a0)+,d0                                  ; 098546
	bra.b    ReadOrderRow_got                          ; 098548
ReadOrderRow_byte:
	move.b   (a0)+,d0                                  ; 09854A
ReadOrderRow_got:
	bsr.b    ReadCell                                  ; 09854C
	lea.l    $C(a5),a5                                 ; 09854E
	dbra     d7,ReadOrderRow_chan                      ; 098552
	rts                                                ; 098556
ReadCell:
	tst.w    $2(a5)                                    ; 098558  d0 = pattern number, a5 = reader
	beq.b    ReadCell_fetch                            ; 09855C  inside a run of empty rows?
	subq.w   #$1,$2(a5)                                ; 09855E
	addq.w   #$1,$0(a5)                                ; 098562
	rts                                                ; 098566
ReadCell_fetch:
	lsl.w    #$2,d0                                    ; 098568  pattern address from the pattern table
	lea.l    Mod_Patterns,a1                           ; 09856A
	adda.w   d0,a1                                     ; 098570
	movea.l  (a1),a1                                   ; 098572
	move.w   Snd_FetchRow,d0                           ; 098574  + 2*(row - rows skipped)
	sub.w    $0(a5),d0                                 ; 09857A
	add.w    d0,d0                                     ; 09857E
	adda.w   d0,a1                                     ; 098580
	moveq    #$0,d0                                    ; 098582
	moveq    #$0,d1                                    ; 098584
	move.b   (a1)+,d0                                  ; 098586
	move.b   (a1)+,d1                                  ; 098588
	cmpi.b   #$FF,d1                                   ; 09858A  "lo,$FF" = lo+1 empty rows (lo = 0: one empty row)
	bne.b    ReadCell_decode                           ; 09858E
	tst.b    d0                                        ; 098590
	beq.b    ReadCell_empty                            ; 098592
	move.w   d0,$2(a5)                                 ; 098594
ReadCell_empty:
	moveq    #$0,d0                                    ; 098598
	moveq    #$0,d1                                    ; 09859A
ReadCell_decode:
	tst.w    $A(a5)                                    ; 09859C  reader muted (FM5 during a jingle)?
	bne.b    ReadCell_chkcmd                           ; 0985A0
	tst.w    $8(a5)                                    ; 0985A2  force the last instrument into the cell (after a jingle)
	beq.b    ReadCell_store                            ; 0985A6
	move.b   d1,d2                                     ; 0985A8
	lsr.b    #$1,d2                                    ; 0985AA
	cmpi.b   #$7C,d2                                   ; 0985AC
	bcc.b    ReadCell_store                            ; 0985B0
	moveq    #$0,d3                                    ; 0985B2
	move.b   d0,d2                                     ; 0985B4
	move.b   d1,d3                                     ; 0985B6
	lsl.w    #$8,d3                                    ; 0985B8
	or.b     d2,d3                                     ; 0985BA
	andi.w   #$1F0,d3                                  ; 0985BC
	bne.b    ReadCell_forced                           ; 0985C0
	moveq    #$0,d2                                    ; 0985C2
	move.b   $6(a5),d2                                 ; 0985C4
	lsl.w    #$1,d2                                    ; 0985C8
	or.b     d2,d0                                     ; 0985CA
	lsr.w    #$8,d2                                    ; 0985CC
	or.b     d2,d1                                     ; 0985CE
ReadCell_forced:
	clr.w    $8(a5)                                    ; 0985D0
ReadCell_store:
	move.b   d0,$4(a5)                                 ; 0985D4  cell to send
	move.b   d1,$5(a5)                                 ; 0985D8
ReadCell_chkcmd:
	move.b   d1,d2                                     ; 0985DC  N >= $7C: command handled here
	lsr.b    #$1,d1                                    ; 0985DE
	cmpi.b   #$7C,d1                                   ; 0985E0
	bcc.b    PatternCommand                            ; 0985E4
	roxr.b   #$1,d2                                    ; 0985E6  remember the instrument (I*8)
	roxr.b   #$1,d0                                    ; 0985E8
	andi.b   #$F8,d0                                   ; 0985EA
	beq.b    ReadCell_exit                             ; 0985EE
	move.b   d0,$6(a5)                                 ; 0985F0
ReadCell_exit:
	rts                                                ; 0985F4
PatternCommand:
	cmpi.b   #$7C,d1                                   ; 0985F6  $7C: nothing (Z80 FMS), $7D speed, $7E jump, $7F break
	beq.w    PatternCommand_cmd7C                      ; 0985FA
	cmpi.b   #$7D,d1                                   ; 0985FE
	beq.b    PatternCommand_cmd7D                      ; 098602
	cmpi.b   #$7E,d1                                   ; 098604
	beq.b    PatternCommand_cmd7E                      ; 098608
	tst.w    Snd_InJingle                              ; 09860A  $7F: pattern break (row := 63)
	beq.b    PatternCommand_breakmusic                 ; 098610
	move.w   #$3F,Snd_JingleRow                        ; 098612
	rts                                                ; 09861A
PatternCommand_breakmusic:
	move.w   #$3F,Snd_MusicRow                         ; 09861C
	rts                                                ; 098624
PatternCommand_cmd7E:
	subq.w   #$1,d0                                    ; 098626  $7E: jump to order position lo (after this row); lo = 0 ends a jingle
	tst.w    Snd_InJingle                              ; 098628
	beq.b    PatternCommand_jumpmusic                  ; 09862E
	move.w   #$3F,Snd_JingleRow                        ; 098630
	move.w   d0,Snd_JingleOrder                        ; 098638
	rts                                                ; 09863E
PatternCommand_jumpmusic:
	move.w   d0,Snd_MusicOrder                         ; 098640
	move.w   #$3F,Snd_MusicRow                         ; 098646
	rts                                                ; 09864E
PatternCommand_cmd7D:
	movea.l  Snd_Mailbox,a6                            ; 098650  $7D: speed = lo & $7F, bit 7 = upper voice bank (mailbox +$E / +$F)
	bsr.w    Snd_StopZ80                               ; 098656
	tst.w    Snd_InJingle                              ; 09865A
	beq.b    PatternCommand_musicspeed                 ; 098660
	clr.b    $F(a6)                                    ; 098662
	btst     #$7,d0                                    ; 098666
	beq.b    PatternCommand_jinglespeed                ; 09866A
	st.b     $F(a6)                                    ; 09866C
PatternCommand_jinglespeed:
	bsr.w    Snd_StartZ80                              ; 098670
	andi.w   #$7F,d0                                   ; 098674
	move.w   d0,Snd_JingleSpeed                        ; 098678
	move.w   d0,Snd_JingleTick                         ; 09867E
	rts                                                ; 098684
PatternCommand_musicspeed:
	clr.b    $E(a6)                                    ; 098686
	btst     #$7,d0                                    ; 09868A
	sf.b     $E(a6)                                    ; 09868E
	beq.b    PatternCommand_setspeed                   ; 098692
	st.b     $E(a6)                                    ; 098694
PatternCommand_setspeed:
	bsr.w    Snd_StartZ80                              ; 098698
	andi.w   #$7F,d0                                   ; 09869C
	move.w   d0,Snd_MusicSpeed                         ; 0986A0
PatternCommand_cmd7C:
	rts                                                ; 0986A6
ClearMusicChans:
	clr.w    Snd_MusicChan+$02                         ; 0986A8  clear skip/RLE counters of the 6 music readers
	clr.w    Snd_MusicChan                             ; 0986AE
	clr.w    Snd_MusicChan+$0E                         ; 0986B4
	clr.w    Snd_MusicChan+$0C                         ; 0986BA
	clr.w    Snd_MusicChan+$1A                         ; 0986C0
	clr.w    Snd_MusicChan+$18                         ; 0986C6
	clr.w    Snd_MusicChan+$26                         ; 0986CC
	clr.w    Snd_MusicChan+$24                         ; 0986D2
	clr.w    Snd_MusicChan+$32                         ; 0986D8
	clr.w    Snd_MusicChan+$30                         ; 0986DE
	clr.w    Snd_MusicChan+$3E                         ; 0986E4
	clr.w    Snd_MusicChan+$3C                         ; 0986EA
	rts                                                ; 0986F0
ClearJingleChan:
	clr.w    Snd_JingleChan+$02                        ; 0986F2
	clr.w    Snd_JingleChan                            ; 0986F8
	rts                                                ; 0986FE
ClearSFXChan:
	clr.w    Snd_SFXChan+$02                           ; 098700
	clr.w    Snd_SFXChan                               ; 098706
	rts                                                ; 09870C

; --------------------------------------------------------------------------
;  SFX sequence (column 5: drum samples only)
; --------------------------------------------------------------------------
SFXSeq_Update:
	subq.w   #$1,d0                                    ; 09870E  d0 = SFX order position + 1
	lea.l    Snd_SFXChan,a5                            ; 098710
	lea.l    Mod_Orders+5,a0                           ; 098716  order column 5
	tst.w    Mod_OrderFlag                             ; 09871C
	beq.b    SFXSeq_Update_chk                         ; 098722
	lea.l    Mod_Orders+10,a0                          ; 098724
SFXSeq_Update_chk:
	addq.w   #$1,Snd_SFXTick                           ; 09872A
	move.w   Snd_SFXSpeed,d4                           ; 098730
	cmp.w    Snd_SFXTick,d4                            ; 098736
	bcc.b    SFXSeq_Update_notyet                      ; 09873C
	clr.w    Snd_SFXTick                               ; 09873E
	bsr.w    SFXSeq_ReadRow                            ; 098744
	addq.w   #$1,Snd_SFXRow                            ; 098748
	cmpi.w   #$40,Snd_SFXRow                           ; 09874E
	bcs.b    SFXSeq_Update_exit                        ; 098756
	clr.w    Snd_SFXChan+$02                           ; 098758
	clr.w    Snd_SFXChan                               ; 09875E
	bsr.w    ClearSFXChan                              ; 098764
	clr.w    Snd_SFXRow                                ; 098768  end of pattern: next position, 0 = end
	addq.w   #$1,Snd_SFXOrder                          ; 09876E
	tst.w    Snd_SFXOrder                              ; 098774
	bne.b    SFXSeq_Update_exit                        ; 09877A
	bsr.w    SFXSeq_End                                ; 09877C
	rts                                                ; 098780
SFXSeq_Update_exit:
	rts                                                ; 098782
SFXSeq_Update_notyet:
	rts                                                ; 098784
SFXSeq_End:
	bsr.w    Snd_StopZ80                               ; 098786
	movea.l  Snd_Mailbox,a6                            ; 09878A
	clr.b    $38(a6)                                   ; 098790
	bsr.w    Snd_StartZ80                              ; 098794
	rts                                                ; 098798
SFXSeq_ReadRow:
	tst.w    Mod_OrderFlag                             ; 09879A
	beq.b    SFXSeq_ReadRow_bytes                      ; 0987A0
	add.w    d0,d0                                     ; 0987A2
SFXSeq_ReadRow_bytes:
	mulu.w   #$6,d0                                    ; 0987A4
	adda.w   d0,a0                                     ; 0987A8
	moveq    #$0,d0                                    ; 0987AA
	tst.w    Mod_OrderFlag                             ; 0987AC
	beq.b    SFXSeq_ReadRow_byte                       ; 0987B2
	move.w   (a0)+,d0                                  ; 0987B4
	bra.b    SFXSeq_ReadRow_got                        ; 0987B6
SFXSeq_ReadRow_byte:
	move.b   (a0)+,d0                                  ; 0987B8
SFXSeq_ReadRow_got:
	tst.w    $2(a5)                                    ; 0987BA
	beq.b    SFXSeq_ReadRow_fetch                      ; 0987BE
	subq.w   #$1,$2(a5)                                ; 0987C0
	addq.w   #$1,$0(a5)                                ; 0987C4
	rts                                                ; 0987C8
SFXSeq_ReadRow_fetch:
	lsl.w    #$2,d0                                    ; 0987CA
	lea.l    Mod_Patterns,a1                           ; 0987CC
	adda.w   d0,a1                                     ; 0987D2
	movea.l  (a1),a1                                   ; 0987D4
	move.w   Snd_SFXRow,d0                             ; 0987D6
	sub.w    $0(a5),d0                                 ; 0987DC
	add.w    d0,d0                                     ; 0987E0
	adda.w   d0,a1                                     ; 0987E2
	moveq    #$0,d0                                    ; 0987E4
	moveq    #$0,d1                                    ; 0987E6
	move.b   (a1)+,d0                                  ; 0987E8
	move.b   (a1)+,d1                                  ; 0987EA
	cmpi.b   #$FF,d1                                   ; 0987EC
	bne.b    SFXSeq_ReadRow_decode                     ; 0987F0
	tst.b    d0                                        ; 0987F2
	beq.b    SFXSeq_ReadRow_empty                      ; 0987F4
	move.w   d0,$2(a5)                                 ; 0987F6
SFXSeq_ReadRow_empty:
	moveq    #$0,d0                                    ; 0987FA
	moveq    #$0,d1                                    ; 0987FC
SFXSeq_ReadRow_decode:
	move.b   d1,d2                                     ; 0987FE  only N $6D-$74 (samples) and commands are used here
	lsr.b    #$1,d1                                    ; 098800
	cmpi.b   #$7C,d1                                   ; 098802
	bcc.b    SFXSeq_ReadRow_cmd                        ; 098806
	subi.b   #$6D,d1                                   ; 098808
	bcs.b    SFXSeq_ReadRow_exit                       ; 09880C
	cmpi.b   #$8,d1                                    ; 09880E
	bcc.b    SFXSeq_ReadRow_exit                       ; 098812
	lea.l    Mod_Samples,a1                            ; 098814  module sample table
	andi.w   #$FF,d1                                   ; 09881A
	add.w    d1,d1                                     ; 09881E
	add.w    d1,d1                                     ; 098820
	adda.w   d1,a1                                     ; 098822
	move.w   d0,d1                                     ; 098824  d1 = rate (cell lo byte)
	move.w   (a1),d0                                   ; 098826
	ori.w    #$8000,d0                                 ; 098828
	move.w   $2(a1),d2                                 ; 09882C
	bsr.w    SendDrumSample                            ; 098830
SFXSeq_ReadRow_exit:
	rts                                                ; 098834
SFXSeq_ReadRow_cmd:
	cmpi.b   #$7C,d1                                   ; 098836
	beq.w    SFXSeq_ReadRow_cmd7C                      ; 09883A
	cmpi.b   #$7D,d1                                   ; 09883E
	beq.b    SFXSeq_ReadRow_cmd7D                      ; 098842
	cmpi.b   #$7E,d1                                   ; 098844
	beq.b    SFXSeq_ReadRow_cmd7E                      ; 098848
	move.w   #$3F,Snd_SFXRow                           ; 09884A
	rts                                                ; 098852
SFXSeq_ReadRow_cmd7E:
	subq.w   #$1,d0                                    ; 098854  $7E: next position lo-1 ($7E 00 = end)
	move.w   #$3F,Snd_SFXRow                           ; 098856
	move.w   d0,Snd_SFXOrder                           ; 09885E
	rts                                                ; 098864
SFXSeq_ReadRow_cmd7D:
	movea.l  Snd_Mailbox,a6                            ; 098866  $7D: speed
	bsr.w    Snd_StopZ80                               ; 09886C
	andi.w   #$7F,d0                                   ; 098870
	move.w   d0,Snd_SFXSpeed                           ; 098874
	move.w   d0,Snd_SFXTick                            ; 09887A
	rts                                                ; 098880
SFXSeq_ReadRow_cmd7C:
	rts                                                ; 098882

; --------------------------------------------------------------------------
;  Samples
; --------------------------------------------------------------------------
Snd_PlaySampleAddr:
	move.l   d0,d3                                     ; 098884  d0 = ROM address, d1 = rate, d2 = length
	lsr.l    #$8,d3                                    ; 098886  bank = address >> 15
	lsr.l    #$7,d3                                    ; 098888
	andi.w   #$7FFF,d0                                 ; 09888A
	ori.w    #$8000,d0                                 ; 09888E
	bra.b    Snd_PlaySampleAddr_store                  ; 098892
	dc.b     $36,$3C,$00,$04                           ; 098894
Snd_PlaySampleAddr_store:
	move.w   d1,Snd_PendRate                           ; 098898
	move.w   d0,Snd_PendAddr                           ; 09889E
	move.w   d2,Snd_PendLen                            ; 0988A4
	move.w   d3,Snd_PendBank                           ; 0988AA
	rts                                                ; 0988B0
SendPendingSample:
	clr.w    Snd_SFXOrder                              ; 0988B2  send the direct sample now
	clr.w    Snd_SFXRow                                ; 0988B8
	move.w   Snd_PendRate,d1                           ; 0988BE
	move.w   Snd_PendAddr,d0                           ; 0988C4
	move.w   Snd_PendLen,d2                            ; 0988CA
	move.w   Snd_PendBank,d3                           ; 0988D0
	clr.w    Snd_PendRate                              ; 0988D6
	bra.b    SendSample                                ; 0988DC
SendDrumSample:
	move.b   #$4,d3                                    ; 0988DE  drum from the module: music sample bank
SendSample:
	tst.w    Snd_Paused                                ; 0988E2  d0 = addr, d1 = rate, d2 = length, d3 = bank
	bne.b    SendSample_exit                           ; 0988E8  not while paused
	movea.l  Snd_Mailbox,a6                            ; 0988EA
	bsr.w    Snd_StopZ80                               ; 0988F0
	move.b   d0,$10(a6)                                ; 0988F4
	lsr.w    #$8,d0                                    ; 0988F8
	move.b   d0,$11(a6)                                ; 0988FA
	move.b   d1,$12(a6)                                ; 0988FE
	move.b   d2,$14(a6)                                ; 098902
	lsr.w    #$8,d2                                    ; 098906
	move.b   d2,$15(a6)                                ; 098908
	st.b     $16(a6)                                   ; 09890C  trigger (Z80 starts it from its wait loop)
	move.b   d3,$42(a6)                                ; 098910
	bsr.w    Snd_StartZ80                              ; 098914
SendSample_exit:
	rts                                                ; 098918

; --------------------------------------------------------------------------
;  Z80 control
; --------------------------------------------------------------------------
Z80_BootStub:
	dc.b     $F3,$AF,$32,$00,$10,$11,$06,$09,$7B       ; 09891A  27 bytes: di / xor a / ld ($1000),a / ld de,<bank> / 9x bank bit / ld a,$FF / ld ($1000),a / jr $
	dc.b     $E6,$01,$32,$00,$60,$CB,$1A,$CB,$1B       ; 098923
	dc.b     $10,$F4,$3E,$FF,$32,$00,$10,$18,$FE       ; 09892C
	dc.b     $00                                       ; 098935
Z80_ResetHold:
	move.w   #$100,($A11100).l                         ; 098936
	move.w   #$0,($A11200).l                           ; 09893E
	moveq    #$9,d0                                    ; 098946
Z80_ResetHold_dly:
	nop                                                ; 098948
	dbra     d0,Z80_ResetHold_dly                      ; 09894A
	move.w   #$100,($A11200).l                         ; 09894E
	rts                                                ; 098956
Z80_LoadDriver:
	bsr.b    Z80_ResetHold                             ; 098958  stub to Z80 $0000 with bank word 0
	lea.l    ($A00000).l,a0                            ; 09895A
	lea.l    Z80_BootStub(pc),a1                       ; 098960
	moveq    #$5,d7                                    ; 098964
Z80_LoadDriver_stub1:
	move.b   (a1)+,(a0)+                               ; 098966
	dbra     d7,Z80_LoadDriver_stub1                   ; 098968
	move.w   #$0,d0                                    ; 09896C
	move.b   d0,(a0)+                                  ; 098970
	lsr.w    #$8,d0                                    ; 098972
	move.b   d0,(a0)+                                  ; 098974
	moveq    #$14,d7                                   ; 098976
Z80_LoadDriver_stub2:
	move.b   (a1)+,(a0)+                               ; 098978
	dbra     d7,Z80_LoadDriver_stub2                   ; 09897A
	bsr.w    Z80_ResetRelease                          ; 09897E
Z80_LoadDriver_waitalive:
	moveq    #$63,d7                                   ; 098982  wait until the stub has written $FF to $1000
Z80_LoadDriver_dly:
	dbra     d7,Z80_LoadDriver_dly                     ; 098984
	move.w   #$100,($A11100).l                         ; 098988
Z80_LoadDriver_waitbus:
	btst.b   #$0,($A11100).l                           ; 098990
	bne.b    Z80_LoadDriver_waitbus                    ; 098998
	move.b   ($A01000).l,d0                            ; 09899A
	bne.b    Z80_LoadDriver_upload                     ; 0989A0
	move.w   #$0,($A11100).l                           ; 0989A2
	bra.b    Z80_LoadDriver_waitalive                  ; 0989AA
Z80_LoadDriver_upload:
	bsr.w    Z80_ResetHold                             ; 0989AC  upload $1400 bytes to Z80 $0C00, then patch $0000 = di / jp $0C00
	lea.l    Z80_Driver(pc),a0                         ; 0989B0
	lea.l    ($A00C00).l,a1                            ; 0989B4
	move.w   #$13FF,d7                                 ; 0989BA
Z80_LoadDriver_copy:
	move.b   (a0)+,(a1)+                               ; 0989BE
	dbra     d7,Z80_LoadDriver_copy                    ; 0989C0
	move.b   #$F3,($A00000).l                          ; 0989C4
	move.b   #$C3,($A00001).l                          ; 0989CC
	move.b   #$0,($A00002).l                           ; 0989D4
	move.b   #$C,($A00003).l                           ; 0989DC
	bsr.b    Z80_ResetRelease                          ; 0989E4
	sf.b     Snd_Z80Held                               ; 0989E6
	rts                                                ; 0989EC
Z80_ResetRelease:
	move.w   #$0,($A11200).l                           ; 0989EE
	move.w   #$0,($A11100).l                           ; 0989F6
	moveq    #$9,d0                                    ; 0989FE
Z80_ResetRelease_dly:
	nop                                                ; 098A00
	dbra     d0,Z80_ResetRelease_dly                   ; 098A02
	move.w   #$100,($A11200).l                         ; 098A06
	rts                                                ; 098A0E
Snd_StopZ80:
	move.b   #$1,($A11100).l                           ; 098A10  request the bus and wait for it
	move.l   d0,-(a7)                                  ; 098A18
Snd_StopZ80_wait:
	move.b   ($A11100).l,d0                            ; 098A1A
	andi.b   #$1,d0                                    ; 098A20
	bne.b    Snd_StopZ80_wait                          ; 098A24
	st.b     Snd_Z80Held                               ; 098A26
	move.l   (a7)+,d0                                  ; 098A2C
	rts                                                ; 098A2E
Snd_StartZ80:
	move.b   #$0,($A11100).l                           ; 098A30
	sf.b     Snd_Z80Held                               ; 098A38
	rts                                                ; 098A3E
Z80_UploadBanks:
	lea.l    Mod_Voices,a1                             ; 098A40  $800 bytes of voices -> Z80 $0400 (64 voices)
	bsr.w    Z80_WaitIdle                              ; 098A46
	lea.l    ($A00400).l,a0                            ; 098A4A
	move.w   #$7FF,d7                                  ; 098A50
Z80_UploadBanks_voices:
	move.b   (a1)+,(a0)+                               ; 098A54
	dbra     d7,Z80_UploadBanks_voices                 ; 098A56
	move.b   #$2,(a6)                                  ; 098A5A  command 2 (reset)
	lea.l    $18(a6),a6                                ; 098A5E
	lea.l    Mod_Samples,a0                            ; 098A62  module sample table -> mailbox +$18
	move.w   #$1F,d7                                   ; 098A68
Z80_UploadBanks_samples:
	move.b   (a0)+,(a6)+                               ; 098A6C
	dbra     d7,Z80_UploadBanks_samples                ; 098A6E
	movea.l  Snd_Mailbox,a0                            ; 098A72  music sample bank
	move.b   #$4,$44(a0)                               ; 098A78
	bsr.w    Snd_StartZ80                              ; 098A7E
	rts                                                ; 098A82
Z80_CmdReset:
	bsr.w    Z80_WaitIdle                              ; 098A84
	move.b   #$2,(a6)                                  ; 098A88
	bsr.w    Snd_StartZ80                              ; 098A8C
	rts                                                ; 098A90
Z80_CmdSilence:
	bsr.w    Z80_WaitIdle                              ; 098A92
	move.b   #$4,(a6)                                  ; 098A96
	bsr.w    Snd_StartZ80                              ; 098A9A
	rts                                                ; 098A9E
Z80_SendTick:
	bsr.w    Z80_WaitIdle                              ; 098AA0  per-frame tick (command 1)
	move.b   Snd_MusicVol,$3A(a6)                      ; 098AA4  mailbox: music volume
	move.w   Snd_MusicOrder,d0                         ; 098AAC  positions 0 and 1 are silent: no tick unless a jingle plays
	cmpi.w   #$2,d0                                    ; 098AB2
	bcc.w    Z80_SendTick_tick                         ; 098AB6
	tst.b    Snd_JingleActive                          ; 098ABA
	bne.w    Z80_SendTick_tick                         ; 098AC0
	bra.b    Z80_SendTick_status                       ; 098AC4
Z80_SendTick_tick:
	move.b   #$1,(a6)                                  ; 098AC6
Z80_SendTick_status:
	move.b   $38(a6),Snd_SFXBusy                       ; 098ACA  read the SFX-busy flag back
	moveq    #$0,d0                                    ; 098AD2  re-check PAL/NTSC
	btst.b   #$6,($A10001).l                           ; 098AD4
	bne.b    Z80_SendTick_ntsc                         ; 098ADC
	addq.w   #$1,d0                                    ; 098ADE
Z80_SendTick_ntsc:
	cmp.w    Snd_IsNTSC,d0                             ; 098AE0
	beq.b    Z80_SendTick_exit                         ; 098AE6
	move.w   d0,Snd_IsNTSC                             ; 098AE8
	clr.w    Snd_NTSCSkip                              ; 098AEE
Z80_SendTick_exit:
	bsr.w    Snd_StartZ80                              ; 098AF4
	rts                                                ; 098AF8
Z80_SendRow:
	tst.b    Snd_JingleActive                          ; 098AFA  new row (command $0A)
	bne.w    Z80_SendRow_send                          ; 098B00
	cmpi.w   #$1,Snd_MusicOrder                        ; 098B04  position 1: never sent
	bne.w    Z80_SendRow_chkempty                      ; 098B0C
	rts                                                ; 098B10
Z80_SendRow_chkempty:
	lea.l    Snd_MusicChan,a0                          ; 098B12  all six cells empty: nothing to send
	moveq    #$0,d0                                    ; 098B18
	or.w     $4(a0),d0                                 ; 098B1A
	or.w     $10(a0),d0                                ; 098B1E
	or.w     $1C(a0),d0                                ; 098B22
	or.w     $28(a0),d0                                ; 098B26
	or.w     $34(a0),d0                                ; 098B2A
	or.w     $40(a0),d0                                ; 098B2E
	bne.w    Z80_SendRow_send                          ; 098B32
	rts                                                ; 098B36
Z80_SendRow_send:
	bsr.w    Z80_WaitIdle                              ; 098B38
	lea.l    $2(a6),a5                                 ; 098B3C
	move.b   $38(a6),Snd_SFXBusy                       ; 098B40
	move.w   #$5,d7                                    ; 098B48
	lea.l    Snd_MusicChan,a0                          ; 098B4C
Z80_SendRow_copy:
	move.b   $4(a0),(a5)+                              ; 098B52  6 cells -> mailbox +2
	move.b   $5(a0),(a5)+                              ; 098B56
	lea.l    $C(a0),a0                                 ; 098B5A
	dbra     d7,Z80_SendRow_copy                       ; 098B5E
	move.b   #$A,(a6)                                  ; 098B62
	bsr.w    Snd_StartZ80                              ; 098B66
	rts                                                ; 098B6A
Snd_SetJinglePan:
	move.l   a6,-(a7)                                  ; 098B6C  d0 = pan byte for FM5 during jingles (0 = voice pan)
	movea.l  Snd_Mailbox,a6                            ; 098B6E
	bsr.w    Snd_StopZ80                               ; 098B74
	move.b   d0,$40(a6)                                ; 098B78
	bsr.w    Snd_StartZ80                              ; 098B7C
	movea.l  (a7)+,a6                                  ; 098B80
	rts                                                ; 098B82
Snd_SetSFXPan:
	move.l   a6,-(a7)                                  ; 098B84  d0 = pan byte for SFX samples (0 = centre)
	movea.l  Snd_Mailbox,a6                            ; 098B86
	bsr.w    Snd_StopZ80                               ; 098B8C
	move.b   d0,$3E(a6)                                ; 098B90
	bsr.w    Snd_StartZ80                              ; 098B94
	movea.l  (a7)+,a6                                  ; 098B98
	rts                                                ; 098B9A
Snd_CutSample:
	movem.l  d0-d2/a0-a1,-(a7)                         ; 098B9C  d1 = rate: replace the playing sample with 2 silent bytes
	move.w   #$2,d2                                    ; 098BA0
	move.l   #SilentSample,d0                          ; 098BA4
	bsr.w    Snd_PlaySampleAddr                        ; 098BAA
	movem.l  (a7)+,d0-d2/a0-a1                         ; 098BAE
	rts                                                ; 098BB2
SilentSample:
	dc.b     $00,$00,$00,$00                           ; 098BB4
Snd_PlayExtSample:
	movem.l  d0-d2/a0-a1,-(a7)                         ; 098BB8  d0 = sample number (1-53), d1 = rate
	lea.l    ExtSampleTable(pc),a0                     ; 098BBC
	lea.l    ($38000).l,a1                             ; 098BC0
	subq.l   #$1,d0                                    ; 098BC6
	bmi.b    Snd_PlayExtSample_exit                    ; 098BC8
	add.w    d0,d0                                     ; 098BCA
	move.w   d0,d2                                     ; 098BCC
	add.w    d0,d0                                     ; 098BCE
	add.w    d2,d0                                     ; 098BD0
	move.w   $4(a0,d0.w),d2                            ; 098BD2
	move.l   (a0,d0.w),d0                              ; 098BD6
	add.l    a1,d0                                     ; 098BDA
	bsr.w    Snd_PlaySampleAddr                        ; 098BDC
Snd_PlayExtSample_exit:
	movem.l  (a7)+,d0-d2/a0-a1                         ; 098BE0
	rts                                                ; 098BE4

; --------------------------------------------------------------------------
;  Extra sample table (Snd_PlayExtSample)
; --------------------------------------------------------------------------
ExtSampleTable:
	dc.w     $0000,$0000,$2567                         ; 098BE6  # 1  $038000-$03A566 (bank $07)
	dc.w     $0000,$2567,$2547                         ; 098BEC  # 2  $03A567-$03CAAD (bank $07)
	dc.w     $0000,$4AAE,$11A6                         ; 098BF2  # 3  $03CAAE-$03DC53 (bank $07)
	dc.w     $0000,$5C54,$1231                         ; 098BF8  # 4  $03DC54-$03EE84 (bank $07)
	dc.w     $0000,$8000,$14A6                         ; 098BFE  # 5  $040000-$0414A5 (bank $08)
	dc.w     $0000,$6E85,$0D9C                         ; 098C04  # 6  $03EE85-$03FC20 (bank $07)
	dc.w     $0000,$94A6,$0F9A                         ; 098C0A  # 7  $0414A6-$04243F (bank $08)
	dc.w     $0000,$A440,$0FA5                         ; 098C10  # 8  $042440-$0433E4 (bank $08)
	dc.w     $0000,$B3E5,$09A3                         ; 098C16  # 9  $0433E5-$043D87 (bank $08)
	dc.w     $0000,$BD88,$0D84                         ; 098C1C  #10  $043D88-$044B0B (bank $08)
	dc.w     $0000,$CB0C,$23D4                         ; 098C22  #11  $044B0C-$046EDF (bank $08)
	dc.w     $0001,$0000,$1750                         ; 098C28  #12  $048000-$04974F (bank $09)
	dc.w     $0001,$1750,$20FB                         ; 098C2E  #13  $049750-$04B84A (bank $09)
	dc.w     $0000,$EEE0,$0911                         ; 098C34  #14  $046EE0-$0477F0 (bank $08)
	dc.w     $0001,$384B,$128C                         ; 098C3A  #15  $04B84B-$04CAD6 (bank $09)
	dc.w     $0001,$4AD7,$08FE                         ; 098C40  #16  $04CAD7-$04D3D4 (bank $09)
	dc.w     $0001,$53D5,$0F1A                         ; 098C46  #17  $04D3D5-$04E2EE (bank $09)
	dc.w     $0000,$F7F1,$075D                         ; 098C4C  #18  $0477F1-$047F4D (bank $08)
	dc.w     $0001,$8000,$314A                         ; 098C52  #19  $050000-$053149 (bank $0A)
	dc.w     $0001,$62EF,$1324                         ; 098C58  #20  $04E2EF-$04F612 (bank $09)
	dc.w     $0001,$B14A,$2A2E                         ; 098C5E  #21  $05314A-$055B77 (bank $0A)
	dc.w     $0001,$DB78,$194B                         ; 098C64  #22  $055B78-$0574C2 (bank $0A)
	dc.w     $0002,$0000,$34AE                         ; 098C6A  #23  $058000-$05B4AD (bank $0B)
	dc.w     $0002,$34AE,$13EC                         ; 098C70  #24  $05B4AE-$05C899 (bank $0B)
	dc.w     $0002,$489A,$0E8E                         ; 098C76  #25  $05C89A-$05D727 (bank $0B)
	dc.w     $0002,$5728,$2198                         ; 098C7C  #26  $05D728-$05F8BF (bank $0B)
	dc.w     $0001,$F4C3,$0A18                         ; 098C82  #27  $0574C3-$057EDA (bank $0A)
	dc.w     $0002,$8000,$18ED                         ; 098C88  #28  $060000-$0618EC (bank $0C)
	dc.w     $0002,$98ED,$1C08                         ; 098C8E  #29  $0618ED-$0634F4 (bank $0C)
	dc.w     $0002,$B4F5,$0F82                         ; 098C94  #30  $0634F5-$064476 (bank $0C)
	dc.w     $0002,$C477,$1BBF                         ; 098C9A  #31  $064477-$066035 (bank $0C)
	dc.w     $0003,$0000,$33DF                         ; 098CA0  #32  $068000-$06B3DE (bank $0D)
	dc.w     $0001,$7613,$05D1                         ; 098CA6  #33  $04F613-$04FBE3 (bank $09)
	dc.w     $0002,$E036,$0C34                         ; 098CAC  #34  $066036-$066C69 (bank $0C)
	dc.w     $0002,$EC6A,$08CC                         ; 098CB2  #35  $066C6A-$067535 (bank $0C)
	dc.w     $0003,$33DF,$2C16                         ; 098CB8  #36  $06B3DF-$06DFF4 (bank $0D)
	dc.w     $0002,$F536,$0AB4                         ; 098CBE  #37  $067536-$067FE9 (bank $0C)
	dc.w     $0003,$5FF5,$0FB2                         ; 098CC4  #38  $06DFF5-$06EFA6 (bank $0D)
	dc.w     $0003,$8000,$5DF8                         ; 098CCA  #39  $070000-$075DF7 (bank $0E)
	dc.w     $0004,$0000,$7A44                         ; 098CD0  #40  $078000-$07FA43 (bank $0F)
	dc.w     $0003,$DDF8,$163A                         ; 098CD6  #41  $075DF8-$077431 (bank $0E)
	dc.w     $0004,$8000,$2DB8                         ; 098CDC  #42  $080000-$082DB7 (bank $10)
	dc.w     $0004,$ADB8,$1480                         ; 098CE2  #43  $082DB8-$084237 (bank $10)
	dc.w     $0004,$C238,$2730                         ; 098CE8  #44  $084238-$086967 (bank $10)
	dc.w     $0005,$0000,$2430                         ; 098CEE  #45  $088000-$08A42F (bank $11)
	dc.w     $0003,$6FA7,$0B40                         ; 098CF4  #46  $06EFA7-$06FAE6 (bank $0D)
	dc.w     $0004,$E968,$0D3E                         ; 098CFA  #47  $086968-$0876A5 (bank $10)
	dc.w     $0005,$2430,$23BC                         ; 098D00  #48  $08A430-$08C7EB (bank $11)
	dc.w     $0005,$47EC,$0E84                         ; 098D06  #49  $08C7EC-$08D66F (bank $11)
	dc.w     $0005,$5670,$1696                         ; 098D0C  #50  $08D670-$08ED05 (bank $11)
	dc.w     $0002,$78C0,$06C0                         ; 098D12  #51  $05F8C0-$05FF7F (bank $0B)
	dc.w     $0005,$8000,$44AA                         ; 098D18  #52  $090000-$0944A9 (bank $12)
	dc.w     $0005,$C4AA,$255E                         ; 098D1E  #53  $0944AA-$096A07 (bank $12)
Z80_WaitIdle:
	movea.l  Snd_Mailbox,a6                            ; 098D24  hold the bus until the Z80 has taken the last command; a6 = mailbox
Z80_WaitIdle_wait:
	bsr.w    Snd_StopZ80                               ; 098D2A
	move.b   (a6),d0                                   ; 098D2E
	beq.b    Z80_WaitIdle_exit                         ; 098D30
	bsr.w    Snd_StartZ80                              ; 098D32
	nop                                                ; 098D36
	nop                                                ; 098D38
	nop                                                ; 098D3A
	nop                                                ; 098D3C
	nop                                                ; 098D3E
	nop                                                ; 098D40
	nop                                                ; 098D42
	nop                                                ; 098D44
	nop                                                ; 098D46
	nop                                                ; 098D48
	nop                                                ; 098D4A
	bra.b    Z80_WaitIdle_wait                         ; 098D4C
	dc.b     $61,$00,$FC,$C0                           ; 098D4E  (dead code: bsr.w Snd_StopZ80)
Z80_WaitIdle_exit:
	rts                                                ; 098D52
Z80_Driver:
	incbin  "Boogerman_Z80.bin"                     ; 098D54  $1400 bytes uploaded to Z80 $0C00, see Kris_Z80_rev3_*.asm
