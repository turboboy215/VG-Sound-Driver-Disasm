; Generated from the ROM by tools/mdis.py (capstone) + m68k_mm.py.
; Syntax: asm68k-style; RAM and module addresses as equates.

Snd_Mailbox              equ  $FFFFF98C   ; long: $A00000 + Z80 mailbox address (read from Z80 $0004)
Snd_IsNTSC               equ  $FFFFF992   ; 1 = 60 Hz console: every 6th frame is skipped
Snd_NTSCSkip             equ  $FFFFF994   ; frame counter 0-5 for the NTSC skip
Snd_PauseReq             equ  $FFFFF996   ; 1 = pause, 2 = resume (handled by the next update)
Snd_Paused               equ  $FFFFF998   ; $FF while paused
Snd_MusicReq             equ  $FFFFF99A   ; order position + 1 requested by Snd_PlayMusic
Snd_MusicTick            equ  $FFFFF99C   ; frames since the last music row
Snd_MusicOrder           equ  $FFFFF99E   ; current order position (song)
Snd_MusicRow             equ  $FFFFF9A0   ; row 0-63 in the current patterns
Snd_SFXOrder             equ  $FFFFF9A2   ; order position + 1 of the SFX sequence (0 = off)
Snd_SFXRow               equ  $FFFFF9A4   ; row of the SFX sequence
Snd_SFXTick              equ  $FFFFF9A6   ; frames since the last SFX-sequence row
Snd_SFXSpeed             equ  $FFFFF9A8   ; SFX-sequence speed
Snd_PendRate             equ  $FFFFF9AA   ; pending direct sample: rate (non-zero = pending)
Snd_PendLen              equ  $FFFFF9AC   ; pending direct sample: length
Snd_PendAddr             equ  $FFFFF9AE   ; pending direct sample: $8000 | (addr & $7FFF)
Snd_PendBank             equ  $FFFFF9B0   ; pending direct sample: ROM bank (addr >> 15)
Snd_JingleOrder          equ  $FFFFF9B2   ; order position of the jingle
Snd_JingleRow            equ  $FFFFF9B4   ; row of the jingle
Snd_FetchRow             equ  $FFFFF9B6   ; row used by ReadCell
Snd_MusicSpeed           equ  $FFFFF9B8   ; music speed: a row every speed+1 frames
Snd_Busy                 equ  $FFFFF9BA   ; $FF while Snd_Update runs (or while paused)
Snd_InJingle             equ  $FFFFF9BC   ; $FF while the jingle column is being read (commands act on the jingle)
Snd_JingleActive         equ  $FFFFF9BE   ; $FF while a jingle plays
Snd_JingleTick           equ  $FFFFF9C0   ; frames since the last jingle row
Snd_JingleSpeed          equ  $FFFFF9C2   ; jingle speed
Snd_JingleReq            equ  $FFFFF9C4   ; order position + 1 requested by Snd_PlayJingle
Snd_MusicChan            equ  $FFFFF9C6   ; 6 x 12 bytes, music channel readers
Snd_JingleChan           equ  $FFFFFA0E   ; 12 bytes, jingle reader (column 4 = FM5)
Snd_SFXChan              equ  $FFFFFA1A   ; 12 bytes, SFX-sequence reader (column 5 = FM6/DAC)
Snd_MusicVol             equ  $FFFFFA26   ; music attenuation (byte)
Snd_JingleVol            equ  $FFFFFA28   ; jingle attenuation (byte)
Snd_Z80Held              equ  $FFFFFA2A   ; $FF while the 68k holds the Z80 bus
Snd_StopJingle           equ  $FFFFFA2C   ; $FF: stop the jingle (set by Snd_PlayMusic)
Snd_SavedJingle          equ  $FFFFFA2E   ; mailbox +1 saved over a pause
Snd_SFXBusy              equ  $FFFFFA30   ; copy of the Z80 SFX-busy flag
Mod_Samples              equ  $1D8000   ; module: 8 x (offset.w, length.w)
Mod_OrderFlag            equ  $1D8020   ; module: $FFFF = word order entries, 0 = byte
Mod_Patterns             equ  $1D8022   ; module: pattern pointer table
Mod_Orders               equ  $1D881E   ; module: order list (6 words per row)
Mod_Voices               equ  $1DFE06   ; voice bank (64 x 32 bytes)

	org	$1E05E6


; ==========================================================================
;  Krisalis sound module (Shaun Hollingworth) -- 68k side, revision 3
;  Mickey Mania - Timeless Adventures of Mickey Mouse (E):
;                  code $1E05E6-$1E1085, Z80 driver $1E1086,
;                  music module $1D8000 (8 samples in bank $3A = $1D0000-$1D7FFF),
;                  voices $1DFE06, extra samples $1C8000-$1CF6F9 (bank $39).
;  Identical to the Boogerman module except for these addresses, the RAM
;  ($FFF98C, absolute word addressing), Snd_PlayMusic also clearing the music
;  volume, and the missing Snd_CutSample.
;  Call: moveq #fn,d7 / jsr Sound_Dispatch, or jsr the function directly.
; ==========================================================================
Sound_Dispatch:
	lsl.w    #$2,d7                                    ; 1E05E6  d7 = function number (0-19), other registers = parameters
	jmp      Sound_JumpTable(pc,d7.w)                  ; 1E05E8
Sound_JumpTable:
	bra.w    Snd_Update                                ; 1E05EC   0 Snd_Update
	bra.w    Snd_PlayMusic                             ; 1E05F0   1 Snd_PlayMusic
	bra.w    Snd_PlayJingle                            ; 1E05F4   2 Snd_PlayJingle
	bra.w    Snd_PlaySFXSeq                            ; 1E05F8   3 Snd_PlaySFXSeq
	bra.w    Snd_Pause                                 ; 1E05FC   4 Snd_Pause
	bra.w    Snd_Resume                                ; 1E0600   5 Snd_Resume
	bra.w    Snd_PlaySampleAddr                        ; 1E0604   6 Snd_PlaySampleAddr
	bra.w    Snd_IsJinglePlaying                       ; 1E0608   7 Snd_IsJinglePlaying
	bra.w    Snd_IsSFXSamplePlaying                    ; 1E060C   8 Snd_IsSFXSamplePlaying
	bra.w    Snd_MusicVolume                           ; 1E0610   9 Snd_MusicVolume
	bra.w    Snd_JingleVolume                          ; 1E0614  10 Snd_JingleVolume
	bra.w    Snd_GetMusicPos                           ; 1E0618  11 Snd_GetMusicPos
	bra.w    Snd_GetJinglePos                          ; 1E061C  12 Snd_GetJinglePos
	bra.w    Snd_GetSFXPos                             ; 1E0620  13 Snd_GetSFXPos
	bra.w    Snd_StopZ80                               ; 1E0624  14 Snd_StopZ80
	bra.w    Snd_StartZ80                              ; 1E0628  15 Snd_StartZ80
	bra.w    Snd_SetJinglePan                          ; 1E062C  16 Snd_SetJinglePan
	bra.w    Snd_SetSFXPan                             ; 1E0630  17 Snd_SetSFXPan
	bra.w    Snd_Init                                  ; 1E0634  18 Snd_Init
	bra.w    Snd_PlayExtSampleJ                        ; 1E0638  19 Snd_PlayExtSample

; --------------------------------------------------------------------------
;  Small API functions
; --------------------------------------------------------------------------
Snd_GetMusicPos:
	move.w   (Snd_MusicOrder).w,d0                     ; 1E063C  out: d0 = order position, d1 = row
	move.w   (Snd_MusicRow).w,d1                       ; 1E0640
	rts                                                ; 1E0644
Snd_GetJinglePos:
	move.w   (Snd_JingleOrder).w,d0                    ; 1E0646
	move.w   (Snd_JingleRow).w,d1                      ; 1E064A
	rts                                                ; 1E064E
Snd_GetSFXPos:
	move.w   (Snd_SFXOrder).w,d0                       ; 1E0650
	move.w   (Snd_SFXRow).w,d1                         ; 1E0654
	rts                                                ; 1E0658
Snd_MusicVolume:
	cmpi.b   #$FF,d0                                   ; 1E065A  d0 = attenuation, $FF = read back
	beq.w    Snd_MusicVolume_get                       ; 1E065E
	move.b   d0,(Snd_MusicVol).w                       ; 1E0662
	rts                                                ; 1E0666
Snd_MusicVolume_get:
	move.b   (Snd_MusicVol).w,d0                       ; 1E0668
	rts                                                ; 1E066C
Snd_JingleVolume:
	cmpi.b   #$FF,d0                                   ; 1E066E
	beq.w    Snd_JingleVolume_get                      ; 1E0672
	move.b   d0,(Snd_JingleVol).w                      ; 1E0676
	rts                                                ; 1E067A
Snd_JingleVolume_get:
	move.b   (Snd_JingleVol).w,d0                      ; 1E067C
	rts                                                ; 1E0680
Snd_IsJinglePlaying:
	tst.w    (Snd_JingleActive).w                      ; 1E0682  Z flag clear while a jingle plays
	rts                                                ; 1E0686
Snd_IsSFXSamplePlaying:
	tst.w    (Snd_SFXBusy).w                           ; 1E0688  Z flag clear while an SFX sample plays
	rts                                                ; 1E068C
Snd_Pause:
	move.w   #$1,(Snd_PauseReq).w                      ; 1E068E  request pause; Snd_Busy keeps the update idle until Snd_Resume
	st.b     (Snd_Paused).w                            ; 1E0694
	rts                                                ; 1E0698
Snd_Resume:
	tst.w    (Snd_Busy).w                              ; 1E069A  only if paused: request resume
	beq.b    Snd_Resume_exit                           ; 1E069E
	move.w   #$2,(Snd_PauseReq).w                      ; 1E06A0
	sf.b     (Snd_Busy).w                              ; 1E06A6
	sf.b     (Snd_Paused).w                            ; 1E06AA
Snd_Resume_exit:
	rts                                                ; 1E06AE
Snd_Init:
	move.w   sr,-(a7)                                  ; 1E06B0  clear the module RAM
	move.w   #$2700,sr                                 ; 1E06B2
	lea.l    (Snd_Mailbox).w,a0                        ; 1E06B6
	lea.l    ($FFFFFA32).w,a1                          ; 1E06BA
	move.w   #$A5,d7                                   ; 1E06BE
Snd_Init_clr:
	clr.b    (a0)+                                     ; 1E06C2
	dbra     d7,Snd_Init_clr                           ; 1E06C4
	nop                                                ; 1E06C8
	bsr.w    Z80_LoadDriver                            ; 1E06CA  reset Z80, run the boot stub, upload the driver
	move.w   #$400,d7                                  ; 1E06CE
Snd_Init_delay:
	dbra     d7,Snd_Init_delay                         ; 1E06D2
	bsr.w    Snd_StopZ80                               ; 1E06D6
	clr.w    (Snd_IsNTSC).w                            ; 1E06DA  PAL/NTSC: bit 6 of the version register = 1 on PAL
	btst.b   #$6,($A10001).l                           ; 1E06DE
	bne.b    Snd_Init_pal                              ; 1E06E6
	addq.w   #$1,(Snd_IsNTSC).w                        ; 1E06E8
Snd_Init_pal:
	moveq    #$0,d0                                    ; 1E06EC  read the mailbox pointer from Z80 $0004/$0005
	move.b   ($A00005).l,d0                            ; 1E06EE
	rol.l    #$8,d0                                    ; 1E06F4
	move.b   ($A00004).l,d0                            ; 1E06F6
	addi.l   #$A00000,d0                               ; 1E06FC
	move.l   d0,(Snd_Mailbox).w                        ; 1E0702
	bsr.w    Snd_StartZ80                              ; 1E0706  release the Z80
	bsr.w    Z80_UploadBanks                           ; 1E070A  upload the voice bank and sample table
	move.w   (a7)+,sr                                  ; 1E070E
	rts                                                ; 1E0710
	dc.b     $51,$F8,$F9,$BA,$42,$78,$F9,$96           ; 1E0712
Snd_PlayExtSampleJ:
	jmp      Snd_PlayExtSample                         ; 1E071A
Snd_PlayMusic:
	addq.w   #$1,d0                                    ; 1E0720  d0 = order position (0 / 1 = silence); also stops a jingle
	move.w   d0,(Snd_MusicReq).w                       ; 1E0722
	st.b     (Snd_StopJingle).w                        ; 1E0726
	sf.b     (Snd_MusicChan+$38).w                     ; 1E072A
	clr.b    (Snd_MusicVol).w                          ; 1E072E  Mickey Mania also resets the music volume
	clr.w    (Snd_PauseReq).w                          ; 1E0732
	clr.w    (Snd_Paused).w                            ; 1E0736
	sf.b     (Snd_Busy).w                              ; 1E073A
	rts                                                ; 1E073E
Snd_PlayJingle:
	tst.w    (Snd_Paused).w                            ; 1E0740  d0 = order position of the jingle (column 4 is played on FM5)
	bne.b    Snd_PlayJingle_exit                       ; 1E0744
	addq.w   #$1,d0                                    ; 1E0746
	move.w   d0,(Snd_JingleReq).w                      ; 1E0748
	sf.b     (Snd_Busy).w                              ; 1E074C
Snd_PlayJingle_exit:
	rts                                                ; 1E0750
Snd_PlaySFXSeq:
	addq.w   #$1,d0                                    ; 1E0752  d0 = order position of the SFX sequence (column 5 = drum samples)
	move.w   d0,(Snd_SFXOrder).w                       ; 1E0754
	clr.w    (Snd_SFXRow).w                            ; 1E0758
	bsr.w    ClearSFXChan                              ; 1E075C
	move.w   #$1,(Snd_SFXSpeed).w                      ; 1E0760  speed 1: a row every 2 frames
	clr.w    (Snd_PendRate).w                          ; 1E0766
	rts                                                ; 1E076A

; --------------------------------------------------------------------------
;  Snd_Update (function 0): call once per frame
; --------------------------------------------------------------------------
Snd_Update:
	btst.b   #$0,($A11100).l                           ; 1E076C  once per frame (VBlank). Works whether or not the caller holds the Z80 bus
	move.w   sr,-(a7)                                  ; 1E0774
	bne.b    Snd_Update_held                           ; 1E0776
	move.w   #$0,($A11100).l                           ; 1E0778
Snd_Update_held:
	bsr.b    Snd_Frame                                 ; 1E0780
	move.w   (a7)+,sr                                  ; 1E0782
	bne.b    Snd_Update_exit                           ; 1E0784
	move.w   #$100,($A11100).l                         ; 1E0786
Snd_Update_wait:
	btst.b   #$0,($A11100).l                           ; 1E078E
	bne.b    Snd_Update_wait                           ; 1E0796
Snd_Update_exit:
	rts                                                ; 1E0798
Snd_Frame:
	tst.w    (Snd_IsNTSC).w                            ; 1E079A  60 Hz: skip every 6th frame so the tempo matches 50 Hz
	beq.b    Snd_Frame_run                             ; 1E079E
	addq.w   #$1,(Snd_NTSCSkip).w                      ; 1E07A0
	cmpi.w   #$6,(Snd_NTSCSkip).w                      ; 1E07A4
	bcs.b    Snd_Frame_run                             ; 1E07AA
	clr.w    (Snd_NTSCSkip).w                          ; 1E07AC
	rts                                                ; 1E07B0
Snd_Frame_run:
	tst.b    (Snd_Busy).w                              ; 1E07B2  re-entered or paused?
	beq.b    Snd_Frame_chkpause                        ; 1E07B6
	rts                                                ; 1E07B8
Snd_Frame_chkpause:
	tst.w    (Snd_PauseReq).w                          ; 1E07BA  pause/resume request?
	beq.w    Snd_Frame_play                            ; 1E07BE
	movem.l  d0-d7/a0-a6,-(a7)                         ; 1E07C2
	move.w   (Snd_PauseReq).w,d0                       ; 1E07C6
	subq.w   #$1,d0                                    ; 1E07CA
	beq.b    Snd_Frame_pause                           ; 1E07CC
	bsr.w    Z80_WaitIdle                              ; 1E07CE  resume: restart voices, restore the jingle state
	move.b   #$7,(a6)                                  ; 1E07D2
	move.w   (Snd_SavedJingle).w,d0                    ; 1E07D6
	move.b   d0,$1(a6)                                 ; 1E07DA
	bsr.w    Snd_StartZ80                              ; 1E07DE
	sf.b     (Snd_Busy).w                              ; 1E07E2
	clr.w    (Snd_PauseReq).w                          ; 1E07E6
	movem.l  (a7)+,d0-d7/a0-a6                         ; 1E07EA
	rts                                                ; 1E07EE
Snd_Frame_pause:
	st.b     (Snd_Busy).w                              ; 1E07F0  pause: save jingle state, silence, stop the SFX sequence
	clr.w    (Snd_PauseReq).w                          ; 1E07F4
	bsr.w    Z80_WaitIdle                              ; 1E07F8
	move.b   $1(a6),d0                                 ; 1E07FC
	move.w   d0,(Snd_SavedJingle).w                    ; 1E0800
	clr.b    $1(a6)                                    ; 1E0804
	bsr.w    Z80_CmdSilence                            ; 1E0808
	bsr.w    Snd_StartZ80                              ; 1E080C
	clr.w    (Snd_SFXOrder).w                          ; 1E0810
	bsr.w    Snd_StartZ80                              ; 1E0814
	movem.l  (a7)+,d0-d7/a0-a6                         ; 1E0818
	rts                                                ; 1E081C
Snd_Frame_play:
	movem.l  d0-d7/a0-a6,-(a7)                         ; 1E081E  normal frame
	st.b     (Snd_Busy).w                              ; 1E0822
	move.w   (Snd_JingleReq).w,d0                      ; 1E0826  jingle requested?
	beq.b    Snd_Frame_music                           ; 1E082A
	subq.w   #$1,d0                                    ; 1E082C
	cmpi.w   #$FF,d0                                   ; 1E082E  (position $FF is treated as 0)
	bne.b    Snd_Frame_jingle                          ; 1E0832
	moveq    #$0,d0                                    ; 1E0834
Snd_Frame_jingle:
	move.w   d0,(Snd_JingleOrder).w                    ; 1E0836
	clr.w    (Snd_JingleReq).w                         ; 1E083A
	clr.w    (Snd_JingleSpeed).w                       ; 1E083E
	clr.w    (Snd_JingleRow).w                         ; 1E0842
	clr.w    (Snd_JingleTick).w                        ; 1E0846
	bsr.w    ClearJingleChan                           ; 1E084A  clear the jingle reader
	st.b     (Snd_JingleActive).w                      ; 1E084E
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0852
	bsr.w    Snd_StopZ80                               ; 1E0856  mailbox: jingle volume, jingle on, jingle voice bank 0
	move.b   (Snd_JingleVol).w,$3C(a6)                 ; 1E085A
	st.b     $1(a6)                                    ; 1E0860
	sf.b     $F(a6)                                    ; 1E0864
	bsr.w    Snd_StartZ80                              ; 1E0868
Snd_Frame_music:
	move.w   (Snd_MusicReq).w,d0                       ; 1E086C  music requested?
	beq.b    Snd_Frame_sfxseq                          ; 1E0870
	subq.w   #$1,d0                                    ; 1E0872
	move.w   d0,(Snd_MusicOrder).w                     ; 1E0874
	clr.w    (Snd_MusicRow).w                          ; 1E0878
	move.w   #$6,(Snd_MusicSpeed).w                    ; 1E087C  default speed 6 (7 frames per row)
	bsr.w    ClearMusicChans                           ; 1E0882
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0886
	bsr.w    Snd_StopZ80                               ; 1E088A
	sf.b     $1(a6)                                    ; 1E088E  mailbox: jingle off, music volume 0
	sf.b     (Snd_MusicChan+$38).w                     ; 1E0892
	sf.b     $3A(a6)                                   ; 1E0896
	bsr.w    Snd_StartZ80                              ; 1E089A
	bsr.w    Z80_CmdReset                              ; 1E089E  Z80: reset channel state, silence
	bsr.w    Z80_CmdSilence                            ; 1E08A2
	bsr.w    ClearMusicChans                           ; 1E08A6
	clr.w    (Snd_MusicReq).w                          ; 1E08AA  mailbox: music voice bank 0
	bsr.w    Snd_StopZ80                               ; 1E08AE
	sf.b     $E(a6)                                    ; 1E08B2
	bsr.w    Snd_StartZ80                              ; 1E08B6
	bra.b    Snd_Frame_exit                            ; 1E08BA
Snd_Frame_sfxseq:
	move.w   (Snd_SFXOrder).w,d0                       ; 1E08BC  SFX sequence running?
	beq.b    Snd_Frame_pending                         ; 1E08C0
	bsr.w    SFXSeq_Update                             ; 1E08C2
Snd_Frame_pending:
	tst.w    (Snd_PendRate).w                          ; 1E08C6  direct sample waiting?
	beq.b    Snd_Frame_musictick                       ; 1E08CA
	bsr.w    SendPendingSample                         ; 1E08CC
Snd_Frame_musictick:
	addq.w   #$1,(Snd_MusicTick).w                     ; 1E08D0  music tick
	move.w   (Snd_MusicSpeed).w,d0                     ; 1E08D4
	cmp.w    (Snd_MusicTick).w,d0                      ; 1E08D8
	bcc.b    Snd_Frame_between                         ; 1E08DC
	clr.w    (Snd_MusicTick).w                         ; 1E08DE
	bsr.w    Music_ReadRow                             ; 1E08E2  read 6 cells
	addq.w   #$1,(Snd_MusicRow).w                      ; 1E08E6
	cmpi.w   #$40,(Snd_MusicRow).w                     ; 1E08EA
	bcs.b    Snd_Frame_rowdone                         ; 1E08F0
	clr.w    (Snd_MusicRow).w                          ; 1E08F2  end of pattern: next order position
	addq.w   #$1,(Snd_MusicOrder).w                    ; 1E08F6
	bsr.w    ClearMusicChans                           ; 1E08FA
Snd_Frame_rowdone:
	bsr.w    Jingle_OnRow                              ; 1E08FE  jingle row (overrides FM5) and send the row
	bsr.w    Z80_SendRow                               ; 1E0902
	bra.b    Snd_Frame_exit                            ; 1E0906
Snd_Frame_between:
	bsr.w    Jingle_OffRow                             ; 1E0908  no music row: jingle-only row or a tick
	beq.b    Snd_Frame_tickonly                        ; 1E090C
	bsr.w    Z80_SendRow                               ; 1E090E
	bra.b    Snd_Frame_exit                            ; 1E0912
Snd_Frame_tickonly:
	bsr.w    Z80_SendTick                              ; 1E0914
Snd_Frame_exit:
	sf.b     (Snd_Busy).w                              ; 1E0918
	movem.l  (a7)+,d0-d7/a0-a6                         ; 1E091C
	rts                                                ; 1E0920

; --------------------------------------------------------------------------
;  Jingle (column 4 of the order list, played on FM5)
; --------------------------------------------------------------------------
Jingle_OnRow:
	bsr.b    Jingle_Step                               ; 1E0922  jingle row read? then its cell replaces the FM5 cell
	bne.b    Jingle_CopyCell                           ; 1E0924
	rts                                                ; 1E0926
Jingle_CopyCell:
	move.w   (Snd_JingleChan+$04).w,(Snd_MusicChan+$34).w; 1E0928
	moveq    #$1,d0                                    ; 1E092E
	rts                                                ; 1E0930
Jingle_OffRow:
	bsr.b    Jingle_Step                               ; 1E0932  jingle-only row: clear the other cells so nothing re-triggers
	beq.b    Jingle_OffRow_none                        ; 1E0934
	clr.w    (Snd_MusicChan+$04).w                     ; 1E0936
	clr.w    (Snd_MusicChan+$10).w                     ; 1E093A
	clr.w    (Snd_MusicChan+$1C).w                     ; 1E093E
	clr.w    (Snd_MusicChan+$28).w                     ; 1E0942
	clr.w    (Snd_MusicChan+$40).w                     ; 1E0946
	bra.b    Jingle_CopyCell                           ; 1E094A
Jingle_OffRow_none:
	rts                                                ; 1E094C
Jingle_Step:
	lea.l    (Snd_JingleChan).w,a5                     ; 1E094E  a5 = jingle reader, a3 = music reader of FM5
	lea.l    (Snd_MusicChan+$30).w,a3                  ; 1E0952
	tst.w    (Snd_StopJingle).w                        ; 1E0956  stop requested?
	bne.w    Jingle_Step_stop                          ; 1E095A
	tst.w    (Snd_JingleActive).w                      ; 1E095E
	beq.w    Jingle_Step_exit                          ; 1E0962
	clr.w    $4(a5)                                    ; 1E0966  clear the jingle cell; clear the FM5 music cell unless it is a command
	move.b   $5(a3),d1                                 ; 1E096A
	lsr.b    #$1,d1                                    ; 1E096E
	cmpi.b   #$7C,d1                                   ; 1E0970
	bcc.b    Jingle_Step_active                        ; 1E0974
	clr.w    $4(a3)                                    ; 1E0976
Jingle_Step_active:
	st.b     (Snd_InJingle).w                          ; 1E097A
	st.b     $A(a3)                                    ; 1E097E  mute the music reader of FM5 (its commands still run)
	move.w   (Snd_JingleOrder).w,d0                    ; 1E0982  order column 4
	move.w   (Snd_JingleRow).w,(Snd_FetchRow).w        ; 1E0986
	lea.l    Mod_Orders+4,a0                           ; 1E098C
	tst.w    Mod_OrderFlag                             ; 1E0992
	beq.b    Jingle_Step_chk                           ; 1E0998
	lea.l    Mod_Orders+8,a0                           ; 1E099A
Jingle_Step_chk:
	move.w   #$0,d7                                    ; 1E09A0
	addq.w   #$1,(Snd_JingleTick).w                    ; 1E09A4
	move.w   (Snd_JingleSpeed).w,d4                    ; 1E09A8
	cmp.w    (Snd_JingleTick).w,d4                     ; 1E09AC
	bcc.b    Jingle_Step_norow                         ; 1E09B0
	clr.w    (Snd_JingleTick).w                        ; 1E09B2
	bsr.w    ReadOrderRow                              ; 1E09B6
	addq.w   #$1,(Snd_JingleRow).w                     ; 1E09BA
	cmpi.w   #$40,(Snd_JingleRow).w                    ; 1E09BE
	bcs.b    Jingle_Step_row                           ; 1E09C4
	bsr.w    ClearJingleChan                           ; 1E09C6  end of pattern
	clr.w    (Snd_JingleRow).w                         ; 1E09CA
	addq.w   #$1,(Snd_JingleOrder).w                   ; 1E09CE
	tst.w    (Snd_JingleOrder).w                       ; 1E09D2  wrapped to 0 ($7E 00): end of jingle, force the FM5 instrument on the next music note
	bne.b    Jingle_Step_row                           ; 1E09D6
	st.b     $8(a3)                                    ; 1E09D8
Jingle_Step_stop:
	sf.b     (Snd_StopJingle).w                        ; 1E09DC  end of jingle
	sf.b     $A(a3)                                    ; 1E09E0
	clr.w    (Snd_JingleActive).w                      ; 1E09E4
	bsr.w    Snd_StopZ80                               ; 1E09E8
	movea.l  (Snd_Mailbox).w,a6                        ; 1E09EC
	sf.b     $1(a6)                                    ; 1E09F0
	bsr.w    Snd_StartZ80                              ; 1E09F4
	moveq    #$0,d0                                    ; 1E09F8
	sf.b     (Snd_InJingle).w                          ; 1E09FA
	rts                                                ; 1E09FE
Jingle_Step_row:
	sf.b     (Snd_InJingle).w                          ; 1E0A00
	moveq    #$1,d0                                    ; 1E0A04
	rts                                                ; 1E0A06
Jingle_Step_norow:
	sf.b     (Snd_InJingle).w                          ; 1E0A08
	moveq    #$0,d0                                    ; 1E0A0C
Jingle_Step_exit:
	rts                                                ; 1E0A0E

; --------------------------------------------------------------------------
;  Pattern reading.  Reader (a5, 12 bytes):
;    +0 rows skipped by RLE   +2 empty rows left   +4/5 cell to send (lo,hi)
;    +6 last instrument*8     +8 force instrument  +A muted (FM5 during a jingle)
; --------------------------------------------------------------------------
Music_ReadRow:
	move.w   (Snd_MusicOrder).w,d0                     ; 1E0A10  music: all 6 columns of the order row
	move.w   (Snd_MusicRow).w,(Snd_FetchRow).w         ; 1E0A14
	lea.l    (Snd_MusicChan+$00).w,a5                  ; 1E0A1A
	move.w   #$5,d7                                    ; 1E0A1E
	lea.l    Mod_Orders,a0                             ; 1E0A22
ReadOrderRow:
	tst.w    Mod_OrderFlag                             ; 1E0A28  d0 = order position, a0 = order column, d7 = columns-1, a5 = readers
	beq.b    ReadOrderRow_bytes                        ; 1E0A2E  word or byte order entries (module flag at +$20)
	add.w    d0,d0                                     ; 1E0A30
ReadOrderRow_bytes:
	andi.l   #$FFFF,d0                                 ; 1E0A32
	mulu.w   #$6,d0                                    ; 1E0A38  6 entries per order row
	adda.w   d0,a0                                     ; 1E0A3C
ReadOrderRow_chan:
	moveq    #$0,d0                                    ; 1E0A3E
	tst.w    Mod_OrderFlag                             ; 1E0A40
	beq.b    ReadOrderRow_byte                         ; 1E0A46
	move.w   (a0)+,d0                                  ; 1E0A48
	bra.b    ReadOrderRow_got                          ; 1E0A4A
ReadOrderRow_byte:
	move.b   (a0)+,d0                                  ; 1E0A4C
ReadOrderRow_got:
	bsr.b    ReadCell                                  ; 1E0A4E
	lea.l    $C(a5),a5                                 ; 1E0A50
	dbra     d7,ReadOrderRow_chan                      ; 1E0A54
	rts                                                ; 1E0A58
ReadCell:
	tst.w    $2(a5)                                    ; 1E0A5A  d0 = pattern number, a5 = reader
	beq.b    ReadCell_fetch                            ; 1E0A5E  inside a run of empty rows?
	subq.w   #$1,$2(a5)                                ; 1E0A60
	addq.w   #$1,(a5)                                  ; 1E0A64
	rts                                                ; 1E0A66
ReadCell_fetch:
	lsl.w    #$2,d0                                    ; 1E0A68  pattern address from the pattern table
	lea.l    Mod_Patterns,a1                           ; 1E0A6A
	adda.w   d0,a1                                     ; 1E0A70
	movea.l  (a1),a1                                   ; 1E0A72
	move.w   (Snd_FetchRow).w,d0                       ; 1E0A74  + 2*(row - rows skipped)
	sub.w    (a5),d0                                   ; 1E0A78
	add.w    d0,d0                                     ; 1E0A7A
	adda.w   d0,a1                                     ; 1E0A7C
	moveq    #$0,d0                                    ; 1E0A7E
	moveq    #$0,d1                                    ; 1E0A80
	move.b   (a1)+,d0                                  ; 1E0A82
	move.b   (a1)+,d1                                  ; 1E0A84
	cmpi.b   #$FF,d1                                   ; 1E0A86  "lo,$FF" = lo+1 empty rows (lo = 0: one empty row)
	bne.b    ReadCell_decode                           ; 1E0A8A
	tst.b    d0                                        ; 1E0A8C
	beq.b    ReadCell_empty                            ; 1E0A8E
	move.w   d0,$2(a5)                                 ; 1E0A90
ReadCell_empty:
	moveq    #$0,d0                                    ; 1E0A94
	moveq    #$0,d1                                    ; 1E0A96
ReadCell_decode:
	tst.w    $A(a5)                                    ; 1E0A98  reader muted (FM5 during a jingle)?
	bne.b    ReadCell_chkcmd                           ; 1E0A9C
	tst.w    $8(a5)                                    ; 1E0A9E  force the last instrument into the cell (after a jingle)
	beq.b    ReadCell_store                            ; 1E0AA2
	move.b   d1,d2                                     ; 1E0AA4
	lsr.b    #$1,d2                                    ; 1E0AA6
	cmpi.b   #$7C,d2                                   ; 1E0AA8
	bcc.b    ReadCell_store                            ; 1E0AAC
	moveq    #$0,d3                                    ; 1E0AAE
	move.b   d0,d2                                     ; 1E0AB0
	move.b   d1,d3                                     ; 1E0AB2
	lsl.w    #$8,d3                                    ; 1E0AB4
	or.b     d2,d3                                     ; 1E0AB6
	andi.w   #$1F0,d3                                  ; 1E0AB8
	bne.b    ReadCell_forced                           ; 1E0ABC
	moveq    #$0,d2                                    ; 1E0ABE
	move.b   $6(a5),d2                                 ; 1E0AC0
	lsl.w    #$1,d2                                    ; 1E0AC4
	or.b     d2,d0                                     ; 1E0AC6
	lsr.w    #$8,d2                                    ; 1E0AC8
	or.b     d2,d1                                     ; 1E0ACA
ReadCell_forced:
	clr.w    $8(a5)                                    ; 1E0ACC
ReadCell_store:
	move.b   d0,$4(a5)                                 ; 1E0AD0  cell to send
	move.b   d1,$5(a5)                                 ; 1E0AD4
ReadCell_chkcmd:
	move.b   d1,d2                                     ; 1E0AD8  N >= $7C: command handled here
	lsr.b    #$1,d1                                    ; 1E0ADA
	cmpi.b   #$7C,d1                                   ; 1E0ADC
	bcc.b    PatternCommand                            ; 1E0AE0
	roxr.b   #$1,d2                                    ; 1E0AE2  remember the instrument (I*8)
	roxr.b   #$1,d0                                    ; 1E0AE4
	andi.b   #$F8,d0                                   ; 1E0AE6
	beq.b    ReadCell_exit                             ; 1E0AEA
	move.b   d0,$6(a5)                                 ; 1E0AEC
ReadCell_exit:
	rts                                                ; 1E0AF0
PatternCommand:
	cmpi.b   #$7C,d1                                   ; 1E0AF2  $7C: nothing (Z80 FMS), $7D speed, $7E jump, $7F break
	beq.w    PatternCommand_cmd7C                      ; 1E0AF6
	cmpi.b   #$7D,d1                                   ; 1E0AFA
	beq.b    PatternCommand_cmd7D                      ; 1E0AFE
	cmpi.b   #$7E,d1                                   ; 1E0B00
	beq.b    PatternCommand_cmd7E                      ; 1E0B04
	tst.w    (Snd_InJingle).w                          ; 1E0B06  $7F: pattern break (row := 63)
	beq.b    PatternCommand_breakmusic                 ; 1E0B0A
	move.w   #$3F,(Snd_JingleRow).w                    ; 1E0B0C
	rts                                                ; 1E0B12
PatternCommand_breakmusic:
	move.w   #$3F,(Snd_MusicRow).w                     ; 1E0B14
	rts                                                ; 1E0B1A
PatternCommand_cmd7E:
	subq.w   #$1,d0                                    ; 1E0B1C  $7E: jump to order position lo (after this row); lo = 0 ends a jingle
	tst.w    (Snd_InJingle).w                          ; 1E0B1E
	beq.b    PatternCommand_jumpmusic                  ; 1E0B22
	move.w   #$3F,(Snd_JingleRow).w                    ; 1E0B24
	move.w   d0,(Snd_JingleOrder).w                    ; 1E0B2A
	rts                                                ; 1E0B2E
PatternCommand_jumpmusic:
	move.w   d0,(Snd_MusicOrder).w                     ; 1E0B30
	move.w   #$3F,(Snd_MusicRow).w                     ; 1E0B34
	rts                                                ; 1E0B3A
PatternCommand_cmd7D:
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0B3C  $7D: speed = lo & $7F, bit 7 = upper voice bank (mailbox +$E / +$F)
	bsr.w    Snd_StopZ80                               ; 1E0B40
	tst.w    (Snd_InJingle).w                          ; 1E0B44
	beq.b    PatternCommand_musicspeed                 ; 1E0B48
	clr.b    $F(a6)                                    ; 1E0B4A
	btst     #$7,d0                                    ; 1E0B4E
	beq.b    PatternCommand_jinglespeed                ; 1E0B52
	st.b     $F(a6)                                    ; 1E0B54
PatternCommand_jinglespeed:
	bsr.w    Snd_StartZ80                              ; 1E0B58
	andi.w   #$7F,d0                                   ; 1E0B5C
	move.w   d0,(Snd_JingleSpeed).w                    ; 1E0B60
	move.w   d0,(Snd_JingleTick).w                     ; 1E0B64
	rts                                                ; 1E0B68
PatternCommand_musicspeed:
	clr.b    $E(a6)                                    ; 1E0B6A
	btst     #$7,d0                                    ; 1E0B6E
	sf.b     $E(a6)                                    ; 1E0B72
	beq.b    PatternCommand_setspeed                   ; 1E0B76
	st.b     $E(a6)                                    ; 1E0B78
PatternCommand_setspeed:
	bsr.w    Snd_StartZ80                              ; 1E0B7C
	andi.w   #$7F,d0                                   ; 1E0B80
	move.w   d0,(Snd_MusicSpeed).w                     ; 1E0B84
PatternCommand_cmd7C:
	rts                                                ; 1E0B88
ClearMusicChans:
	clr.w    (Snd_MusicChan+$02).w                     ; 1E0B8A  clear skip/RLE counters of the 6 music readers
	clr.w    (Snd_MusicChan+$00).w                     ; 1E0B8E
	clr.w    (Snd_MusicChan+$0E).w                     ; 1E0B92
	clr.w    (Snd_MusicChan+$0C).w                     ; 1E0B96
	clr.w    (Snd_MusicChan+$1A).w                     ; 1E0B9A
	clr.w    (Snd_MusicChan+$18).w                     ; 1E0B9E
	clr.w    (Snd_MusicChan+$26).w                     ; 1E0BA2
	clr.w    (Snd_MusicChan+$24).w                     ; 1E0BA6
	clr.w    (Snd_MusicChan+$32).w                     ; 1E0BAA
	clr.w    (Snd_MusicChan+$30).w                     ; 1E0BAE
	clr.w    (Snd_MusicChan+$3E).w                     ; 1E0BB2
	clr.w    (Snd_MusicChan+$3C).w                     ; 1E0BB6
	rts                                                ; 1E0BBA
ClearJingleChan:
	clr.w    (Snd_JingleChan+$02).w                    ; 1E0BBC
	clr.w    (Snd_JingleChan).w                        ; 1E0BC0
	rts                                                ; 1E0BC4
ClearSFXChan:
	clr.w    (Snd_SFXChan+$02).w                       ; 1E0BC6
	clr.w    (Snd_SFXChan).w                           ; 1E0BCA
	rts                                                ; 1E0BCE

; --------------------------------------------------------------------------
;  SFX sequence (column 5: drum samples only)
; --------------------------------------------------------------------------
SFXSeq_Update:
	subq.w   #$1,d0                                    ; 1E0BD0  d0 = SFX order position + 1
	lea.l    (Snd_SFXChan).w,a5                        ; 1E0BD2
	lea.l    Mod_Orders+5,a0                           ; 1E0BD6  order column 5
	tst.w    Mod_OrderFlag                             ; 1E0BDC
	beq.b    SFXSeq_Update_chk                         ; 1E0BE2
	lea.l    Mod_Orders+10,a0                          ; 1E0BE4
SFXSeq_Update_chk:
	addq.w   #$1,(Snd_SFXTick).w                       ; 1E0BEA
	move.w   (Snd_SFXSpeed).w,d4                       ; 1E0BEE
	cmp.w    (Snd_SFXTick).w,d4                        ; 1E0BF2
	bcc.b    SFXSeq_Update_notyet                      ; 1E0BF6
	clr.w    (Snd_SFXTick).w                           ; 1E0BF8
	bsr.w    SFXSeq_ReadRow                            ; 1E0BFC
	addq.w   #$1,(Snd_SFXRow).w                        ; 1E0C00
	cmpi.w   #$40,(Snd_SFXRow).w                       ; 1E0C04
	bcs.b    SFXSeq_Update_exit                        ; 1E0C0A
	clr.w    (Snd_SFXChan+$02).w                       ; 1E0C0C
	clr.w    (Snd_SFXChan).w                           ; 1E0C10
	bsr.b    ClearSFXChan                              ; 1E0C14
	clr.w    (Snd_SFXRow).w                            ; 1E0C16  end of pattern: next position, 0 = end
	addq.w   #$1,(Snd_SFXOrder).w                      ; 1E0C1A
	tst.w    (Snd_SFXOrder).w                          ; 1E0C1E
	bne.b    SFXSeq_Update_exit                        ; 1E0C22
	bsr.w    SFXSeq_End                                ; 1E0C24
	rts                                                ; 1E0C28
SFXSeq_Update_exit:
	rts                                                ; 1E0C2A
SFXSeq_Update_notyet:
	rts                                                ; 1E0C2C
SFXSeq_End:
	bsr.w    Snd_StopZ80                               ; 1E0C2E
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0C32
	clr.b    $38(a6)                                   ; 1E0C36
	bsr.w    Snd_StartZ80                              ; 1E0C3A
	rts                                                ; 1E0C3E
SFXSeq_ReadRow:
	tst.w    Mod_OrderFlag                             ; 1E0C40
	beq.b    SFXSeq_ReadRow_bytes                      ; 1E0C46
	add.w    d0,d0                                     ; 1E0C48
SFXSeq_ReadRow_bytes:
	mulu.w   #$6,d0                                    ; 1E0C4A
	adda.w   d0,a0                                     ; 1E0C4E
	moveq    #$0,d0                                    ; 1E0C50
	tst.w    Mod_OrderFlag                             ; 1E0C52
	beq.b    SFXSeq_ReadRow_byte                       ; 1E0C58
	move.w   (a0)+,d0                                  ; 1E0C5A
	bra.b    SFXSeq_ReadRow_got                        ; 1E0C5C
SFXSeq_ReadRow_byte:
	move.b   (a0)+,d0                                  ; 1E0C5E
SFXSeq_ReadRow_got:
	tst.w    $2(a5)                                    ; 1E0C60
	beq.b    SFXSeq_ReadRow_fetch                      ; 1E0C64
	subq.w   #$1,$2(a5)                                ; 1E0C66
	addq.w   #$1,(a5)                                  ; 1E0C6A
	rts                                                ; 1E0C6C
SFXSeq_ReadRow_fetch:
	lsl.w    #$2,d0                                    ; 1E0C6E
	lea.l    Mod_Patterns,a1                           ; 1E0C70
	adda.w   d0,a1                                     ; 1E0C76
	movea.l  (a1),a1                                   ; 1E0C78
	move.w   (Snd_SFXRow).w,d0                         ; 1E0C7A
	sub.w    (a5),d0                                   ; 1E0C7E
	add.w    d0,d0                                     ; 1E0C80
	adda.w   d0,a1                                     ; 1E0C82
	moveq    #$0,d0                                    ; 1E0C84
	moveq    #$0,d1                                    ; 1E0C86
	move.b   (a1)+,d0                                  ; 1E0C88
	move.b   (a1)+,d1                                  ; 1E0C8A
	cmpi.b   #$FF,d1                                   ; 1E0C8C
	bne.b    SFXSeq_ReadRow_decode                     ; 1E0C90
	tst.b    d0                                        ; 1E0C92
	beq.b    SFXSeq_ReadRow_empty                      ; 1E0C94
	move.w   d0,$2(a5)                                 ; 1E0C96
SFXSeq_ReadRow_empty:
	moveq    #$0,d0                                    ; 1E0C9A
	moveq    #$0,d1                                    ; 1E0C9C
SFXSeq_ReadRow_decode:
	move.b   d1,d2                                     ; 1E0C9E  only N $6D-$74 (samples) and commands are used here
	lsr.b    #$1,d1                                    ; 1E0CA0
	cmpi.b   #$7C,d1                                   ; 1E0CA2
	bcc.b    SFXSeq_ReadRow_cmd                        ; 1E0CA6
	subi.b   #$6D,d1                                   ; 1E0CA8
	bcs.b    SFXSeq_ReadRow_exit                       ; 1E0CAC
	cmpi.b   #$8,d1                                    ; 1E0CAE
	bcc.b    SFXSeq_ReadRow_exit                       ; 1E0CB2
	lea.l    Mod_Samples,a1                            ; 1E0CB4  module sample table
	andi.w   #$FF,d1                                   ; 1E0CBA
	add.w    d1,d1                                     ; 1E0CBE
	add.w    d1,d1                                     ; 1E0CC0
	adda.w   d1,a1                                     ; 1E0CC2
	move.w   d0,d1                                     ; 1E0CC4  d1 = rate (cell lo byte)
	move.w   (a1),d0                                   ; 1E0CC6
	ori.w    #$8000,d0                                 ; 1E0CC8
	move.w   $2(a1),d2                                 ; 1E0CCC
	bsr.w    SendDrumSample                            ; 1E0CD0
SFXSeq_ReadRow_exit:
	rts                                                ; 1E0CD4
SFXSeq_ReadRow_cmd:
	cmpi.b   #$7C,d1                                   ; 1E0CD6
	beq.w    SFXSeq_ReadRow_cmd7C                      ; 1E0CDA
	cmpi.b   #$7D,d1                                   ; 1E0CDE
	beq.b    SFXSeq_ReadRow_cmd7D                      ; 1E0CE2
	cmpi.b   #$7E,d1                                   ; 1E0CE4
	beq.b    SFXSeq_ReadRow_cmd7E                      ; 1E0CE8
	move.w   #$3F,(Snd_SFXRow).w                       ; 1E0CEA
	rts                                                ; 1E0CF0
SFXSeq_ReadRow_cmd7E:
	subq.w   #$1,d0                                    ; 1E0CF2  $7E: next position lo-1 ($7E 00 = end)
	move.w   #$3F,(Snd_SFXRow).w                       ; 1E0CF4
	move.w   d0,(Snd_SFXOrder).w                       ; 1E0CFA
	rts                                                ; 1E0CFE
SFXSeq_ReadRow_cmd7D:
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0D00  $7D: speed
	bsr.w    Snd_StopZ80                               ; 1E0D04
	andi.w   #$7F,d0                                   ; 1E0D08
	move.w   d0,(Snd_SFXSpeed).w                       ; 1E0D0C
	move.w   d0,(Snd_SFXTick).w                        ; 1E0D10
	rts                                                ; 1E0D14
SFXSeq_ReadRow_cmd7C:
	rts                                                ; 1E0D16

; --------------------------------------------------------------------------
;  Samples
; --------------------------------------------------------------------------
Snd_PlaySampleAddr:
	move.l   d0,d3                                     ; 1E0D18  d0 = ROM address, d1 = rate, d2 = length
	lsr.l    #$8,d3                                    ; 1E0D1A  bank = address >> 15
	lsr.l    #$7,d3                                    ; 1E0D1C
	andi.w   #$7FFF,d0                                 ; 1E0D1E
	ori.w    #$8000,d0                                 ; 1E0D22
	bra.b    Snd_PlaySampleAddr_store                  ; 1E0D26
	dc.b     $36,$3C,$00,$3A                           ; 1E0D28
Snd_PlaySampleAddr_store:
	move.w   d1,(Snd_PendRate).w                       ; 1E0D2C
	move.w   d0,(Snd_PendAddr).w                       ; 1E0D30
	move.w   d2,(Snd_PendLen).w                        ; 1E0D34
	move.w   d3,(Snd_PendBank).w                       ; 1E0D38
	rts                                                ; 1E0D3C
SendPendingSample:
	clr.w    (Snd_SFXOrder).w                          ; 1E0D3E  send the direct sample now
	clr.w    (Snd_SFXRow).w                            ; 1E0D42
	move.w   (Snd_PendRate).w,d1                       ; 1E0D46
	move.w   (Snd_PendAddr).w,d0                       ; 1E0D4A
	move.w   (Snd_PendLen).w,d2                        ; 1E0D4E
	move.w   (Snd_PendBank).w,d3                       ; 1E0D52
	clr.w    (Snd_PendRate).w                          ; 1E0D56
	bra.b    SendSample                                ; 1E0D5A
SendDrumSample:
	move.b   #$3A,d3                                   ; 1E0D5C  drum from the module: music sample bank
SendSample:
	tst.w    (Snd_Paused).w                            ; 1E0D60  d0 = addr, d1 = rate, d2 = length, d3 = bank
	bne.b    SendSample_exit                           ; 1E0D64  not while paused
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0D66
	bsr.w    Snd_StopZ80                               ; 1E0D6A
	move.b   d0,$10(a6)                                ; 1E0D6E
	lsr.w    #$8,d0                                    ; 1E0D72
	move.b   d0,$11(a6)                                ; 1E0D74
	move.b   d1,$12(a6)                                ; 1E0D78
	move.b   d2,$14(a6)                                ; 1E0D7C
	lsr.w    #$8,d2                                    ; 1E0D80
	move.b   d2,$15(a6)                                ; 1E0D82
	st.b     $16(a6)                                   ; 1E0D86  trigger (Z80 starts it from its wait loop)
	move.b   d3,$42(a6)                                ; 1E0D8A
	bsr.w    Snd_StartZ80                              ; 1E0D8E
SendSample_exit:
	rts                                                ; 1E0D92

; --------------------------------------------------------------------------
;  Z80 control
; --------------------------------------------------------------------------
Z80_BootStub:
	dc.b     $F3,$AF,$32,$00,$10,$11,$06,$09,$7B       ; 1E0D94  27 bytes: di / xor a / ld ($1000),a / ld de,<bank> / 9x bank bit / ld a,$FF / ld ($1000),a / jr $
	dc.b     $E6,$01,$32,$00,$60,$CB,$1A,$CB,$1B       ; 1E0D9D
	dc.b     $10,$F4,$3E,$FF,$32,$00,$10,$18,$FE       ; 1E0DA6
	dc.b     $00                                       ; 1E0DAF
Z80_ResetHold:
	move.w   #$100,($A11100).l                         ; 1E0DB0
	move.w   #$0,($A11200).l                           ; 1E0DB8
	moveq    #$9,d0                                    ; 1E0DC0
Z80_ResetHold_dly:
	nop                                                ; 1E0DC2
	dbra     d0,Z80_ResetHold_dly                      ; 1E0DC4
	move.w   #$100,($A11200).l                         ; 1E0DC8
	rts                                                ; 1E0DD0
Z80_LoadDriver:
	bsr.b    Z80_ResetHold                             ; 1E0DD2  stub to Z80 $0000 with bank word 0
	lea.l    ($A00000).l,a0                            ; 1E0DD4
	lea.l    Z80_BootStub(pc),a1                       ; 1E0DDA
	moveq    #$5,d7                                    ; 1E0DDE
Z80_LoadDriver_stub1:
	move.b   (a1)+,(a0)+                               ; 1E0DE0
	dbra     d7,Z80_LoadDriver_stub1                   ; 1E0DE2
	move.w   #$0,d0                                    ; 1E0DE6
	move.b   d0,(a0)+                                  ; 1E0DEA
	lsr.w    #$8,d0                                    ; 1E0DEC
	move.b   d0,(a0)+                                  ; 1E0DEE
	moveq    #$14,d7                                   ; 1E0DF0
Z80_LoadDriver_stub2:
	move.b   (a1)+,(a0)+                               ; 1E0DF2
	dbra     d7,Z80_LoadDriver_stub2                   ; 1E0DF4
	bsr.w    Z80_ResetRelease                          ; 1E0DF8
Z80_LoadDriver_waitalive:
	moveq    #$63,d7                                   ; 1E0DFC  wait until the stub has written $FF to $1000
Z80_LoadDriver_dly:
	dbra     d7,Z80_LoadDriver_dly                     ; 1E0DFE
	move.w   #$100,($A11100).l                         ; 1E0E02
Z80_LoadDriver_waitbus:
	btst.b   #$0,($A11100).l                           ; 1E0E0A
	bne.b    Z80_LoadDriver_waitbus                    ; 1E0E12
	move.b   ($A01000).l,d0                            ; 1E0E14
	bne.b    Z80_LoadDriver_upload                     ; 1E0E1A
	move.w   #$0,($A11100).l                           ; 1E0E1C
	bra.b    Z80_LoadDriver_waitalive                  ; 1E0E24
Z80_LoadDriver_upload:
	bsr.b    Z80_ResetHold                             ; 1E0E26  upload $1400 bytes to Z80 $0C00, then patch $0000 = di / jp $0C00
	lea.l    Z80_Driver(pc),a0                         ; 1E0E28
	lea.l    ($A00C00).l,a1                            ; 1E0E2C
	move.w   #$13FF,d7                                 ; 1E0E32
Z80_LoadDriver_copy:
	move.b   (a0)+,(a1)+                               ; 1E0E36
	dbra     d7,Z80_LoadDriver_copy                    ; 1E0E38
	move.b   #$F3,($A00000).l                          ; 1E0E3C
	move.b   #$C3,($A00001).l                          ; 1E0E44
	move.b   #$0,($A00002).l                           ; 1E0E4C
	move.b   #$C,($A00003).l                           ; 1E0E54
	bsr.b    Z80_ResetRelease                          ; 1E0E5C
	sf.b     (Snd_Z80Held).w                           ; 1E0E5E
	rts                                                ; 1E0E62
Z80_ResetRelease:
	move.w   #$0,($A11200).l                           ; 1E0E64
	move.w   #$0,($A11100).l                           ; 1E0E6C
	moveq    #$9,d0                                    ; 1E0E74
Z80_ResetRelease_dly:
	nop                                                ; 1E0E76
	dbra     d0,Z80_ResetRelease_dly                   ; 1E0E78
	move.w   #$100,($A11200).l                         ; 1E0E7C
	rts                                                ; 1E0E84
Snd_StopZ80:
	move.b   #$1,($A11100).l                           ; 1E0E86  request the bus and wait for it
	move.l   d0,-(a7)                                  ; 1E0E8E
Snd_StopZ80_wait:
	move.b   ($A11100).l,d0                            ; 1E0E90
	andi.b   #$1,d0                                    ; 1E0E96
	bne.b    Snd_StopZ80_wait                          ; 1E0E9A
	st.b     (Snd_Z80Held).w                           ; 1E0E9C
	move.l   (a7)+,d0                                  ; 1E0EA0
	rts                                                ; 1E0EA2
Snd_StartZ80:
	move.b   #$0,($A11100).l                           ; 1E0EA4
	sf.b     (Snd_Z80Held).w                           ; 1E0EAC
	rts                                                ; 1E0EB0
Z80_UploadBanks:
	lea.l    Mod_Voices(pc),a1                         ; 1E0EB2  $800 bytes of voices -> Z80 $0400 (64 voices)
	bsr.w    Z80_WaitIdle                              ; 1E0EB6
	lea.l    ($A00400).l,a0                            ; 1E0EBA
	move.w   #$7FF,d7                                  ; 1E0EC0
Z80_UploadBanks_voices:
	move.b   (a1)+,(a0)+                               ; 1E0EC4
	dbra     d7,Z80_UploadBanks_voices                 ; 1E0EC6
	move.b   #$2,(a6)                                  ; 1E0ECA  command 2 (reset)
	lea.l    $18(a6),a6                                ; 1E0ECE
	lea.l    Mod_Samples,a0                            ; 1E0ED2  module sample table -> mailbox +$18
	move.w   #$1F,d7                                   ; 1E0ED8
Z80_UploadBanks_samples:
	move.b   (a0)+,(a6)+                               ; 1E0EDC
	dbra     d7,Z80_UploadBanks_samples                ; 1E0EDE
	movea.l  (Snd_Mailbox).w,a0                        ; 1E0EE2  music sample bank
	move.b   #$3A,$44(a0)                              ; 1E0EE6
	bsr.b    Snd_StartZ80                              ; 1E0EEC
	rts                                                ; 1E0EEE
Z80_CmdReset:
	bsr.w    Z80_WaitIdle                              ; 1E0EF0
	move.b   #$2,(a6)                                  ; 1E0EF4
	bsr.b    Snd_StartZ80                              ; 1E0EF8
	rts                                                ; 1E0EFA
Z80_CmdSilence:
	bsr.w    Z80_WaitIdle                              ; 1E0EFC
	move.b   #$4,(a6)                                  ; 1E0F00
	bsr.b    Snd_StartZ80                              ; 1E0F04
	rts                                                ; 1E0F06
Z80_SendTick:
	bsr.w    Z80_WaitIdle                              ; 1E0F08  per-frame tick (command 1)
	move.b   (Snd_MusicVol).w,$3A(a6)                  ; 1E0F0C  mailbox: music volume
	move.w   (Snd_MusicOrder).w,d0                     ; 1E0F12  positions 0 and 1 are silent: no tick unless a jingle plays
	cmpi.w   #$2,d0                                    ; 1E0F16
	bcc.w    Z80_SendTick_tick                         ; 1E0F1A
	tst.b    (Snd_JingleActive).w                      ; 1E0F1E
	bne.w    Z80_SendTick_tick                         ; 1E0F22
	bra.b    Z80_SendTick_status                       ; 1E0F26
Z80_SendTick_tick:
	move.b   #$1,(a6)                                  ; 1E0F28
Z80_SendTick_status:
	move.b   $38(a6),(Snd_SFXBusy).w                   ; 1E0F2C  read the SFX-busy flag back
	moveq    #$0,d0                                    ; 1E0F32  re-check PAL/NTSC
	btst.b   #$6,($A10001).l                           ; 1E0F34
	bne.b    Z80_SendTick_ntsc                         ; 1E0F3C
	addq.w   #$1,d0                                    ; 1E0F3E
Z80_SendTick_ntsc:
	cmp.w    (Snd_IsNTSC).w,d0                         ; 1E0F40
	beq.b    Z80_SendTick_exit                         ; 1E0F44
	move.w   d0,(Snd_IsNTSC).w                         ; 1E0F46
	clr.w    (Snd_NTSCSkip).w                          ; 1E0F4A
Z80_SendTick_exit:
	bsr.w    Snd_StartZ80                              ; 1E0F4E
	rts                                                ; 1E0F52
Z80_SendRow:
	tst.b    (Snd_JingleActive).w                      ; 1E0F54  new row (command $0A)
	bne.w    Z80_SendRow_send                          ; 1E0F58
	cmpi.w   #$1,(Snd_MusicOrder).w                    ; 1E0F5C  position 1: never sent
	bne.w    Z80_SendRow_chkempty                      ; 1E0F62
	rts                                                ; 1E0F66
Z80_SendRow_chkempty:
	lea.l    (Snd_MusicChan+$00).w,a0                  ; 1E0F68  all six cells empty: nothing to send
	moveq    #$0,d0                                    ; 1E0F6C
	or.w     $4(a0),d0                                 ; 1E0F6E
	or.w     $10(a0),d0                                ; 1E0F72
	or.w     $1C(a0),d0                                ; 1E0F76
	or.w     $28(a0),d0                                ; 1E0F7A
	or.w     $34(a0),d0                                ; 1E0F7E
	or.w     $40(a0),d0                                ; 1E0F82
	bne.w    Z80_SendRow_send                          ; 1E0F86
	rts                                                ; 1E0F8A
Z80_SendRow_send:
	bsr.w    Z80_WaitIdle                              ; 1E0F8C
	lea.l    $2(a6),a5                                 ; 1E0F90
	move.b   $38(a6),(Snd_SFXBusy).w                   ; 1E0F94
	move.w   #$5,d7                                    ; 1E0F9A
	lea.l    (Snd_MusicChan+$00).w,a0                  ; 1E0F9E
Z80_SendRow_copy:
	move.b   $4(a0),(a5)+                              ; 1E0FA2  6 cells -> mailbox +2
	move.b   $5(a0),(a5)+                              ; 1E0FA6
	lea.l    $C(a0),a0                                 ; 1E0FAA
	dbra     d7,Z80_SendRow_copy                       ; 1E0FAE
	move.b   #$A,(a6)                                  ; 1E0FB2
	bsr.w    Snd_StartZ80                              ; 1E0FB6
	rts                                                ; 1E0FBA
Snd_SetJinglePan:
	move.l   a6,-(a7)                                  ; 1E0FBC  d0 = pan byte for FM5 during jingles (0 = voice pan)
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0FBE
	bsr.w    Snd_StopZ80                               ; 1E0FC2
	move.b   d0,$40(a6)                                ; 1E0FC6
	bsr.w    Snd_StartZ80                              ; 1E0FCA
	movea.l  (a7)+,a6                                  ; 1E0FCE
	rts                                                ; 1E0FD0
Snd_SetSFXPan:
	move.l   a6,-(a7)                                  ; 1E0FD2  d0 = pan byte for SFX samples (0 = centre)
	movea.l  (Snd_Mailbox).w,a6                        ; 1E0FD4
	bsr.w    Snd_StopZ80                               ; 1E0FD8
	move.b   d0,$3E(a6)                                ; 1E0FDC
	bsr.w    Snd_StartZ80                              ; 1E0FE0
	movea.l  (a7)+,a6                                  ; 1E0FE4
Snd_CutSample:
	rts                                                ; 1E0FE6  d1 = rate: replace the playing sample with 2 silent bytes
Snd_PlayExtSample:
	movem.l  d0-d2/a0-a1,-(a7)                         ; 1E0FE8  d0 = sample number (1-11), d1 = rate
	lea.l    ExtSampleTable(pc),a0                     ; 1E0FEC
	lea.l    ($1C8000).l,a1                            ; 1E0FF0
	subq.l   #$1,d0                                    ; 1E0FF6
	bmi.b    Snd_PlayExtSample_exit                    ; 1E0FF8
	add.w    d0,d0                                     ; 1E0FFA
	move.w   d0,d2                                     ; 1E0FFC
	add.w    d0,d0                                     ; 1E0FFE
	add.w    d2,d0                                     ; 1E1000
	move.w   $4(a0,d0.w),d2                            ; 1E1002
	move.l   (a0,d0.w),d0                              ; 1E1006
	add.l    a1,d0                                     ; 1E100A
	bsr.w    Snd_PlaySampleAddr                        ; 1E100C
Snd_PlayExtSample_exit:
	movem.l  (a7)+,d0-d2/a0-a1                         ; 1E1010
	rts                                                ; 1E1014

; --------------------------------------------------------------------------
;  Extra sample table (Snd_PlayExtSample)
; --------------------------------------------------------------------------
ExtSampleTable:
	dc.w     $0000,$0000,$0CCC                         ; 1E1016  # 1  $1C8000-$1C8CCB (bank $39)
	dc.w     $0000,$0CCC,$0B5E                         ; 1E101C  # 2  $1C8CCC-$1C9829 (bank $39)
	dc.w     $0000,$182A,$08D6                         ; 1E1022  # 3  $1C982A-$1CA0FF (bank $39)
	dc.w     $0000,$2100,$0DE4                         ; 1E1028  # 4  $1CA100-$1CAEE3 (bank $39)
	dc.w     $0000,$2EE4,$0B76                         ; 1E102E  # 5  $1CAEE4-$1CBA59 (bank $39)
	dc.w     $0000,$3A5A,$09CA                         ; 1E1034  # 6  $1CBA5A-$1CC423 (bank $39)
	dc.w     $0000,$4424,$09E2                         ; 1E103A  # 7  $1CC424-$1CCE05 (bank $39)
	dc.w     $0000,$4E06,$0D92                         ; 1E1040  # 8  $1CCE06-$1CDB97 (bank $39)
	dc.w     $0000,$5B98,$0D16                         ; 1E1046  # 9  $1CDB98-$1CE8AD (bank $39)
	dc.w     $0000,$68AE,$080C                         ; 1E104C  #10  $1CE8AE-$1CF0B9 (bank $39)
	dc.w     $0000,$70BA,$0640                         ; 1E1052  #11  $1CF0BA-$1CF6F9 (bank $39)
Z80_WaitIdle:
	movea.l  (Snd_Mailbox).w,a6                        ; 1E1058  hold the bus until the Z80 has taken the last command; a6 = mailbox
Z80_WaitIdle_wait:
	bsr.w    Snd_StopZ80                               ; 1E105C
	move.b   (a6),d0                                   ; 1E1060
	beq.b    Z80_WaitIdle_exit                         ; 1E1062
	bsr.w    Snd_StartZ80                              ; 1E1064
	nop                                                ; 1E1068
	nop                                                ; 1E106A
	nop                                                ; 1E106C
	nop                                                ; 1E106E
	nop                                                ; 1E1070
	nop                                                ; 1E1072
	nop                                                ; 1E1074
	nop                                                ; 1E1076
	nop                                                ; 1E1078
	nop                                                ; 1E107A
	nop                                                ; 1E107C
	bra.b    Z80_WaitIdle_wait                         ; 1E107E
	dc.b     $61,$00,$FE,$04                           ; 1E1080
Z80_WaitIdle_exit:
	rts                                                ; 1E1084
Z80_Driver:
	incbin  "MickeyMania_Z80.bin"                   ; 1E1086  $1400 bytes uploaded to Z80 $0C00, see Kris_Z80_rev3_*.asm
