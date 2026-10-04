; Indiana Jones and the Last Crusade (JE) - 68000 side of the Tiertex sound engine
; capstone disassembly, labels/comments added. Data tables are described in Tiertex_SoundEngine.md
; Z80 driver image $F0E2-$F6F7 is disassembled separately (IndyJones_Z80_driver.asm)


;==============================================================================
; VBlank excerpt: music cue -> SFX
;==============================================================================

; Part of VBlank: if the song has a cue list and the Z80 set $FFFFFF (cmd F4), play the next SFX from the list
VBlank_MusicCue:
	move.w #$1, $FF7E14.l                   ; 000274: 33fc000100ff7e14     
	addq.w #$1, $FF7E16.l                   ; 00027C: 527900ff7e16         
	tst.w $FFA138.l                         ; 000282: 4a7900ffa138         cue list enabled for this song?
	beq.w loc_0002D4                        ; 000288: 6700004a             
	tst.b $FFFF.w                           ; 00028C: 4a38ffff             Z80 cmd F4 sets $FFFFFF
	beq.w loc_0002D4                        ; 000290: 67000042             
	movem.l d0-d7/a0-a6, -(a7)              ; 000294: 48e7fffe             
	move.w $FFA13A.l, d0                    ; 000298: 303900ffa13a         
	add.w d0, d0                            ; 00029E: d040                 
	movea.l $FFA13C.l, a0                   ; 0002A0: 207900ffa13c         
	cmpi.w #$FFFF, (a0, d0.w)               ; 0002A6: 0c70ffff0000         $FFFF terminates -> wrap to start
	bne.w VBC_Play                          ; 0002AC: 6600000c             
	move.w #$0, d0                          ; 0002B0: 303c0000             
	move.w d0, $FFA13A.l                    ; 0002B4: 33c000ffa13a         

VBC_Play:
	move.w (a0, d0.w), d0                   ; 0002BA: 30300000             
	jsr PlaySFX.l                           ; 0002BE: 4eb90000f838         
	addq.w #$1, $FFA13A.l                   ; 0002C4: 527900ffa13a         
	movem.l (a7)+, d0-d7/a0-a6              ; 0002CA: 4cdf7fff             
	move.b #$0, $FFFF.w                     ; 0002CE: 11fc0000ffff         acknowledge

loc_0002D4:
	rte                                     ; 0002D4: 4e73                 

;==============================================================================
; Driver loader
;==============================================================================

; Request Z80 bus and wait for grant
Z80_RequestBus:
	move.w #$100, Z80_BUSREQ.l              ; 00F07E: 33fc010000a11100     
	btst.b #$0, Z80_BUSREQ.l                ; 00F086: 0839000000a11100     
	bne.b Z80_RequestBus                    ; 00F08E: 66ee                 
	rts                                     ; 00F090: 4e75                 

; Reset Z80, copy driver ($616 bytes) to Z80 $0000 and default voices to $0A00, run
LoadSoundDriver:
	move.w #$100, Z80_RESET.l               ; 00F092: 33fc010000a11200     
	bsr.b Z80_RequestBus                    ; 00F09A: 61e2                 
	lea.l Z80_RAM.l, a0                     ; 00F09C: 41f900a00000         
	lea.l Z80_DriverImage.l, a1             ; 00F0A2: 43f90000f0e2         
	move.w #$615, d7                        ; 00F0A8: 3e3c0615             $616 bytes

loc_00F0AC:
	move.b (a1)+, (a0)+                     ; 00F0AC: 10d9                 
	dbra d7, loc_00F0AC                     ; 00F0AE: 51cffffc             
	lea.l DefaultVoices.l, a1               ; 00F0B2: 43f90000fef8         default voice bank
	lea.l Z80_VoiceBank.l, a2               ; 00F0B8: 45f900a00a00         
	move.w #$3DF, d7                        ; 00F0BE: 3e3c03df             

loc_00F0C2:
	move.b (a1)+, (a2)+                     ; 00F0C2: 14d9                 
	dbra d7, loc_00F0C2                     ; 00F0C4: 51cffffc             
	move.w #$0, Z80_RESET.l                 ; 00F0C8: 33fc000000a11200     reset Z80 (assert)
	move.w #$0, Z80_BUSREQ.l                ; 00F0D0: 33fc000000a11100     
	move.w #$100, Z80_RESET.l               ; 00F0D8: 33fc010000a11200     release reset -> Z80 runs
	rts                                     ; 00F0E0: 4e75                 

;==============================================================================
; Sound API
;==============================================================================

LoadDefaultVoices:
	bsr.w Z80_RequestBus                    ; 00F6F8: 6100f984             
	lea.l DefaultVoices.l, a1               ; 00F6FC: 43f90000fef8         
	lea.l Z80_VoiceBank.l, a2               ; 00F702: 45f900a00a00         
	move.w #$3DF, d7                        ; 00F708: 3e3c03df             

loc_00F70C:
	move.b (a1)+, (a2)+                     ; 00F70C: 14d9                 
	dbra d7, loc_00F70C                     ; 00F70E: 51cffffc             
	move.w #$0, Z80_BUSREQ.l                ; 00F712: 33fc000000a11100     
	rts                                     ; 00F71A: 4e75                 
	rts                                     ; 00F71C: 4e75                 

; d0.w = song number (0 = silence). Copies all tracks to Z80 $0E00+, sets start requests, loads voice bank
PlayMusic:
	move.w d0, $FFA148.l                    ; 00F71E: 33c000ffa148         current song
	bsr.w Z80_RequestBus                    ; 00F724: 6100f958             
	move.w #$0, $FFA138.l                   ; 00F728: 33fc000000ffa138     
	move.l #$0, $FFA13C.l                   ; 00F730: 23fc0000000000ffa13c 
	move.w #$0, $FFA13A.l                   ; 00F73A: 33fc000000ffa13a     
	move.b #$0, Z80_DAC_HalfVol.l           ; 00F742: 13fc000000a009e4     DAC half volume off
	tst.w d0                                ; 00F74A: 4a40                 
	beq.w PM_CopyTracks                     ; 00F74C: 67000036             
	lea.l CueFlagTable.l, a5                ; 00F750: 4bf90000fdc0         cue flag per song (all 0 in Indy)
	move.w d0, d1                           ; 00F756: 3200                 
	subq.w #$1, d1                          ; 00F758: 5341                 
	move.b (a5, d1.w), d1                   ; 00F75A: 12351000             
	ext.w d1                                ; 00F75E: 4881                 
	move.w d1, $FFA138.l                    ; 00F760: 33c100ffa138         
	move.w d0, d1                           ; 00F766: 3200                 
	subq.w #$1, d1                          ; 00F768: 5341                 
	add.w d1, d1                            ; 00F76A: d241                 
	add.w d1, d1                            ; 00F76C: d241                 
	lea.l CueListTable.l, a5                ; 00F76E: 4bf90000fdd0         cue list pointer
	move.l (a5, d1.w), $FFA13C.l            ; 00F774: 23f5100000ffa13c     
	move.b #$1, Z80_DAC_HalfVol.l           ; 00F77C: 13fc000100a009e4     music playing -> DAC at half volume

PM_CopyTracks:
	lea.l Z80_SongData.l, a5                ; 00F784: 4bf900a00e00         track data destination in Z80 RAM
	lea.l SongTable.l, a0                   ; 00F78A: 41f90000fb14         SongTable + song*36
	lsl.w #$2, d0                           ; 00F790: e548                 
	adda.w d0, a0                           ; 00F792: d0c0                 
	lsl.w #$3, d0                           ; 00F794: e748                 
	adda.w d0, a0                           ; 00F796: d0c0                 
	lea.l $18(a0), a3                       ; 00F798: 47e80018             a3 -> 6 track lengths
	lea.l SilentTrack.l, a2                 ; 00F79C: 45f90000f05a         default = SilentTrack
	moveq #$28, d7                          ; 00F7A2: 7e28                 silent stub length 40 (d7+1-1)
	lea.l Z80_Mus_FM1.l, a4                 ; 00F7A4: 49f900a00800         track RAM FM1..FM6, $30 apart
	bsr.w PM_CopyTrack                      ; 00F7AA: 61000056             
	lea.l $30(a4), a4                       ; 00F7AE: 49ec0030             
	bsr.w PM_CopyTrack                      ; 00F7B2: 6100004e             
	lea.l $30(a4), a4                       ; 00F7B6: 49ec0030             
	bsr.w PM_CopyTrack                      ; 00F7BA: 61000046             
	lea.l $30(a4), a4                       ; 00F7BE: 49ec0030             
	bsr.w PM_CopyTrack                      ; 00F7C2: 6100003e             
	lea.l $30(a4), a4                       ; 00F7C6: 49ec0030             
	bsr.w PM_CopyTrack                      ; 00F7CA: 61000036             
	lea.l $30(a4), a4                       ; 00F7CE: 49ec0030             
	bsr.w PM_CopyTrack                      ; 00F7D2: 6100002e             
	move.w $FFA148.l, d7                    ; 00F7D6: 3e3900ffa148         
	asl.w #$2, d7                           ; 00F7DC: e547                 
	lea.l VoiceBankTable.l, a1              ; 00F7DE: 43f900016f5c         voice bank pointer table
	movea.l (a1, d7.w), a1                  ; 00F7E4: 22717000             
	lea.l Z80_VoiceBank.l, a2               ; 00F7E8: 45f900a00a00         -> Z80 $0A00 ($3E0 bytes)
	move.w #$3DF, d7                        ; 00F7EE: 3e3c03df             

loc_00F7F2:
	move.b (a1)+, (a2)+                     ; 00F7F2: 14d9                 
	dbra d7, loc_00F7F2                     ; 00F7F4: 51cffffc             
	move.w #$0, Z80_BUSREQ.l                ; 00F7F8: 33fc000000a11100     
	rts                                     ; 00F800: 4e75                 

; a0 -> ROM track pointer (0 = silent stub, <0 = leave channel), a3 -> length, a4 = Z80 track RAM, a5 = Z80 dest
PM_CopyTrack:
	movea.l a2, a1                          ; 00F802: 224a                 
	move.l d7, d1                           ; 00F804: 2207                 
	move.w (a3)+, d2                        ; 00F806: 341b                 
	move.l (a0)+, d0                        ; 00F808: 2018                 
	bmi.b PMCT_Skip                         ; 00F80A: 6b1e                 
	beq.b PMCT_Copy                         ; 00F80C: 6704                 
	movea.l d0, a1                          ; 00F80E: 2240                 
	move.w d2, d1                           ; 00F810: 3202                 

PMCT_Copy:
	move.l a5, d0                           ; 00F812: 200d                 
	move.b d0, $5(a4)                       ; 00F814: 19400005             start pointer (IX+5/6)
	lsr.w #$8, d0                           ; 00F818: e048                 
	move.b d0, $6(a4)                       ; 00F81A: 19400006             
	subq.w #$1, d1                          ; 00F81E: 5341                 
	bsr.w CopyBytes                         ; 00F820: 6100000e             
	move.b #$1, $7(a4)                      ; 00F824: 197c00010007         IX+7 = 1 : start request

PMCT_Skip:
	rts                                     ; 00F82A: 4e75                 

CopySFX256:
	move.w #$FF, d1                         ; 00F82C: 323c00ff             

CopyBytes:
	move.b (a1)+, (a5)+                     ; 00F830: 1ad9                 
	dbra d1, CopyBytes                      ; 00F832: 51c9fffc             
	rts                                     ; 00F836: 4e75                 

; d0.w = SFX id (bits 0-11) | forced channel (bits 12-15: 0 = auto, 3-6 = FM3-FM6)
PlaySFX:
	movem.l d0-d7/a0-a5, -(a7)              ; 00F838: 48e7fffc             
	move.w d0, d1                           ; 00F83C: 3200                 
	andi.w #$FFF, d0                        ; 00F83E: 02400fff             
	cmpi.w #$2B, d0                         ; 00F842: 0c40002b             ids >= $2B ignored
	bcs.b PSFX_Valid                        ; 00F846: 6504                 
	bra.w PSFX_Exit                         ; 00F848: 600001b6             

PSFX_Valid:
	eor.w d0, d1                            ; 00F84C: b141                 
	rol.w #$4, d1                           ; 00F84E: e959                 d1 = requested channel
	bsr.w Z80_RequestBus                    ; 00F850: 6100f82c             
	move.w $FFA140.l, $FFA142.l             ; 00F854: 33f900ffa14000ffa142 previous / current SFX id
	move.w d0, $FFA140.l                    ; 00F85E: 33c000ffa140         
	lea.l SfxTable.l, a0                    ; 00F864: 41f90000fe18         SfxTable
	lsl.w #$2, d0                           ; 00F86A: e548                 
	movea.l (a0, d0.w), a1                  ; 00F86C: 22700000             
	move.b (a0, d0.w), d0                   ; 00F870: 10300000             top byte = DAC sample number (0 = FM SFX)
	beq.w PSFX_FM                           ; 00F874: 670000aa             
	move.l a1, d2                           ; 00F878: 2409                 
	lea.l DacTable.l, a1                    ; 00F87A: 43f90000fec4         DacTable
	andi.w #$FF, d0                         ; 00F880: 024000ff             
	lsl.w #$2, d0                           ; 00F884: e548                 
	move.w (a1, d0.w), d4                   ; 00F886: 38310000             length (negative = looped)
	move.w $2(a1, d0.w), d3                 ; 00F88A: 36310002             rate in Hz
	neg.w d4                                ; 00F88E: 4444                 
	andi.l #$FFFFFF, d2                     ; 00F890: 028200ffffff         
	movea.l d2, a1                          ; 00F896: 2242                 
	move.w #$F, d5                          ; 00F898: 3a3c000f             bank = addr >> 15
	lsr.l d5, d2                            ; 00F89C: eaaa                 
	move.b d2, d5                           ; 00F89E: 1a02                 
	lsr.w #$8, d2                           ; 00F8A0: e04a                 
	move.b d5, Z80_DAC_Bank.l               ; 00F8A2: 13c500a009fc         DAC_Bank (non-zero = trigger)
	move.b d2, Z80_DAC_Bank+1.l             ; 00F8A8: 13c200a009fd         
	tst.w d4                                ; 00F8AE: 4a44                 
	bpl.b loc_00F8B8                        ; 00F8B0: 6a06                 
	clr.b d2                                ; 00F8B2: 4202                 
	clr.b d5                                ; 00F8B4: 4205                 
	neg.w d4                                ; 00F8B6: 4444                 

loc_00F8B8:
	move.b d5, Z80_DAC_LoopBank.l           ; 00F8B8: 13c500a009fe         DAC_LoopBank (cleared again at $F9E6!)
	move.l a1, d2                           ; 00F8BE: 2409                 
	andi.w #$7FFF, d2                       ; 00F8C0: 02427fff             address in $8000 window
	ori.w #$8000, d2                        ; 00F8C4: 00428000             
	move.b d2, Z80_DAC_Addr.l               ; 00F8C8: 13c200a009f8         
	lsr.w #$8, d2                           ; 00F8CE: e04a                 
	move.b d2, Z80_DAC_Addr+1.l             ; 00F8D0: 13c200a009f9         
	move.b d4, Z80_DAC_Len.l                ; 00F8D6: 13c400a009fa         DAC_Len
	lsr.w #$8, d4                           ; 00F8DC: e04c                 
	move.b d4, Z80_DAC_Len+1.l              ; 00F8DE: 13c400a009fb         
	move.l #$CE2A, d4                       ; 00F8E4: 283c0000ce2a         TA = $400 - 52778/rate
	divu.w d3, d4                           ; 00F8EA: 88c3                 
	move.w #$400, d3                        ; 00F8EC: 363c0400             
	sub.w d4, d3                            ; 00F8F0: 9644                 
	move.w d3, d4                           ; 00F8F2: 3803                 
	andi.w #$3, d4                          ; 00F8F4: 02440003             
	move.b d4, Z80_DAC_TimerA.l             ; 00F8F8: 13c400a009f6         DAC_TimerA low 2 bits
	lsr.w #$2, d3                           ; 00F8FE: e44b                 
	move.b d3, Z80_DAC_TimerA+1.l           ; 00F900: 13c300a009f7         DAC_TimerA high 8 bits
	lea.l SilentTrack.l, a1                 ; 00F906: 43f90000f05a         FM6 SFX slot gets a silent track (FM6 = DAC)
	move.w #$0, d1                          ; 00F90C: 323c0000             
	lea.l Z80_SFX_FM6.l, a0                 ; 00F910: 41f900a009b0         
	lea.l Z80_SfxSlotFM6.l, a5              ; 00F916: 4bf900a01e00         
	bra.w PSFX_Start                        ; 00F91C: 600000a8             

; FM SFX: choose channel. Auto order FM6, FM4, FM3, FM5; drop SFX if all busy
PSFX_FM:
	tst.w d1                                ; 00F920: 4a41                 
	beq.b PSFX_Auto                         ; 00F922: 6718                 
	cmpi.w #$6, d1                          ; 00F924: 0c410006             
	beq.b PSFX_Ch6                          ; 00F928: 6766                 
	cmpi.w #$5, d1                          ; 00F92A: 0c410005             
	beq.b PSFX_Ch5                          ; 00F92E: 676e                 
	cmpi.w #$4, d1                          ; 00F930: 0c410004             
	beq.b PSFX_Ch4                          ; 00F934: 6776                 
	cmpi.w #$3, d1                          ; 00F936: 0c410003             
	beq.b PSFX_Ch3                          ; 00F93A: 677e                 

PSFX_Auto:
	lea.l Z80_SFX_FM6.l, a0                 ; 00F93C: 41f900a009b0         
	lea.l Z80_SfxSlotFM6.l, a5              ; 00F942: 4bf900a01e00         
	move.b (a0), d0                         ; 00F948: 1010                 
	or.b $1(a0), d0                         ; 00F94A: 80280001             
	beq.b PSFX_Start                        ; 00F94E: 6776                 
	lea.l Z80_SFX_FM4.l, a0                 ; 00F950: 41f900a00950         
	lea.l Z80_SfxSlotFM4.l, a5              ; 00F956: 4bf900a01c00         
	move.b (a0), d0                         ; 00F95C: 1010                 
	or.b $1(a0), d0                         ; 00F95E: 80280001             
	beq.b PSFX_Start                        ; 00F962: 6762                 
	lea.l Z80_SFX_FM3.l, a0                 ; 00F964: 41f900a00920         
	lea.l Z80_SfxSlotFM3.l, a5              ; 00F96A: 4bf900a01b00         
	move.b (a0), d0                         ; 00F970: 1010                 
	or.b $1(a0), d0                         ; 00F972: 80280001             
	beq.b PSFX_Start                        ; 00F976: 674e                 
	lea.l Z80_SFX_FM5.l, a0                 ; 00F978: 41f900a00980         
	lea.l Z80_SfxSlotFM5.l, a5              ; 00F97E: 4bf900a01d00         
	move.b (a0), d0                         ; 00F984: 1010                 
	or.b $1(a0), d0                         ; 00F986: 80280001             
	beq.b PSFX_Start                        ; 00F98A: 673a                 
	bra.w PSFX_Release                      ; 00F98C: 6000006a             

PSFX_Ch6:
	lea.l Z80_SFX_FM6.l, a0                 ; 00F990: 41f900a009b0         
	lea.l Z80_SfxSlotFM6.l, a5              ; 00F996: 4bf900a01e00         
	bra.b PSFX_Start                        ; 00F99C: 6028                 

PSFX_Ch5:
	lea.l Z80_SFX_FM5.l, a0                 ; 00F99E: 41f900a00980         
	lea.l Z80_SfxSlotFM5.l, a5              ; 00F9A4: 4bf900a01d00         
	bra.b PSFX_Start                        ; 00F9AA: 601a                 

PSFX_Ch4:
	lea.l Z80_SFX_FM4.l, a0                 ; 00F9AC: 41f900a00950         
	lea.l Z80_SfxSlotFM4.l, a5              ; 00F9B2: 4bf900a01c00         
	bra.b PSFX_Start                        ; 00F9B8: 600c                 

PSFX_Ch3:
	lea.l Z80_SFX_FM3.l, a0                 ; 00F9BA: 41f900a00920         
	lea.l Z80_SfxSlotFM3.l, a5              ; 00F9C0: 4bf900a01b00         

; Copy 256 bytes of SFX data to the channel slot, clear freq base & loop bank, set start request
PSFX_Start:
	move.l a5, d0                           ; 00F9C6: 200d                 
	move.b d0, $5(a0)                       ; 00F9C8: 11400005             
	lsr.w #$8, d0                           ; 00F9CC: e048                 
	move.b d0, $6(a0)                       ; 00F9CE: 11400006             
	bsr.w CopySFX256                        ; 00F9D2: 6100fe58             256 bytes -> Z80 $1B00/$1C00/$1D00/$1E00
	move.b #$0, d0                          ; 00F9D6: 103c0000             
	move.b #$0, d1                          ; 00F9DA: 123c0000             
	move.b d0, $11(a0)                      ; 00F9DE: 11400011             IX+$11/12 freq base = 0
	move.b d1, $12(a0)                      ; 00F9E2: 11410012             
	clr.b Z80_DAC_LoopBank.l                ; 00F9E6: 423900a009fe         DAC_LoopBank = 0
	clr.b Z80_DAC_LoopBank+1.l              ; 00F9EC: 423900a009ff         
	move.b #$1, $7(a0)                      ; 00F9F2: 117c00010007         start request

PSFX_Release:
	move.w #$0, Z80_BUSREQ.l                ; 00F9F8: 33fc000000a11100     

PSFX_Exit:
	movem.l (a7)+, d0-d7/a0-a5              ; 00FA00: 4cdf3fff             
	rts                                     ; 00FA04: 4e75                 

; Unused in Indy: 68k-timed DAC playback. a4 = data, d1.w = length, d3.w = rate (Hz)
PlayDAC_68k:
	bsr.w Z80_RequestBus                    ; 00FA06: 6100f676             
	move.w #$0, $FFA144.l                   ; 00FA0A: 33fc000000ffa144     
	lea.l YM2612.l, a5                      ; 00FA12: 4bf900a04000         
	lsl.l #$8, d7                           ; 00FA18: e18f                 
	lsl.l #$8, d7                           ; 00FA1A: e18f                 
	lsl.l #$8, d7                           ; 00FA1C: e18f                 
	lsl.l #$8, d7                           ; 00FA1E: e18f                 
	move.b #$27, (a5)                       ; 00FA20: 1abc0027             
	lsl.l #$8, d7                           ; 00FA24: e18f                 
	move.b #$15, $1(a5)                     ; 00FA26: 1b7c00150001         
	lsl.l #$8, d7                           ; 00FA2C: e18f                 
	lsl.l #$8, d7                           ; 00FA2E: e18f                 
	lsl.l #$8, d7                           ; 00FA30: e18f                 
	lsl.l #$8, d7                           ; 00FA32: e18f                 
	move.l #$CE2A, d4                       ; 00FA34: 283c0000ce2a         TA = $400 - 52778/rate
	divu.w d3, d4                           ; 00FA3A: 88c3                 
	move.w #$400, d3                        ; 00FA3C: 363c0400             
	sub.w d4, d3                            ; 00FA40: 9644                 
	move.w d3, d4                           ; 00FA42: 3803                 
	andi.w #$3, d4                          ; 00FA44: 02440003             
	lsr.w #$2, d3                           ; 00FA48: e44b                 
	move.b #$24, (a5)                       ; 00FA4A: 1abc0024             
	lsl.l #$8, d7                           ; 00FA4E: e18f                 
	move.b d3, $1(a5)                       ; 00FA50: 1b430001             
	lsl.l #$8, d7                           ; 00FA54: e18f                 
	lsl.l #$8, d7                           ; 00FA56: e18f                 
	lsl.l #$8, d7                           ; 00FA58: e18f                 
	lsl.l #$8, d7                           ; 00FA5A: e18f                 
	move.b #$25, (a5)                       ; 00FA5C: 1abc0025             
	lsl.l #$8, d7                           ; 00FA60: e18f                 
	move.b d4, $1(a5)                       ; 00FA62: 1b440001             
	lsl.l #$8, d7                           ; 00FA66: e18f                 
	lsl.l #$8, d7                           ; 00FA68: e18f                 
	lsl.l #$8, d7                           ; 00FA6A: e18f                 
	lsl.l #$8, d7                           ; 00FA6C: e18f                 

PD68_Loop:
	move.b #$27, (a5)                       ; 00FA6E: 1abc0027             

PD68_WaitBusy:
	move.b (a5), d0                         ; 00FA72: 1015                 
	btst.b #$7, d0                          ; 00FA74: 08000007             
	bne.b PD68_WaitBusy                     ; 00FA78: 66f8                 

PD68_WaitTA:
	move.b (a5), d0                         ; 00FA7A: 1015                 
	andi.b #$1, d0                          ; 00FA7C: 02000001             
	beq.b PD68_WaitTA                       ; 00FA80: 67f8                 
	move.b #$1F, $1(a5)                     ; 00FA82: 1b7c001f0001         
	tst.w $FFA144.l                         ; 00FA88: 4a7900ffa144         
	bne.w PD68_Write                        ; 00FA8E: 66000038             
	move.w #$1, $FFA144.l                   ; 00FA92: 33fc000100ffa144     
	move.b #$2B, (a5)                       ; 00FA9A: 1abc002b             
	lsl.l #$8, d7                           ; 00FA9E: e18f                 
	lsl.l #$8, d7                           ; 00FAA0: e18f                 
	move.b #$80, $1(a5)                     ; 00FAA2: 1b7c00800001         
	lsl.l #$8, d7                           ; 00FAA8: e18f                 
	lsl.l #$8, d7                           ; 00FAAA: e18f                 
	lsl.l #$8, d7                           ; 00FAAC: e18f                 
	lsl.l #$8, d7                           ; 00FAAE: e18f                 
	move.b #$B6, $2(a5)                     ; 00FAB0: 1b7c00b60002         
	lsl.l #$8, d7                           ; 00FAB6: e18f                 
	lsl.l #$8, d7                           ; 00FAB8: e18f                 
	move.b #$C0, $3(a5)                     ; 00FABA: 1b7c00c00003         
	lsl.l #$8, d7                           ; 00FAC0: e18f                 
	lsl.l #$8, d7                           ; 00FAC2: e18f                 
	lsl.l #$8, d7                           ; 00FAC4: e18f                 
	lsl.l #$8, d7                           ; 00FAC6: e18f                 

PD68_Write:
	move.b #$2A, (a5)                       ; 00FAC8: 1abc002a             
	move.b (a4)+, $1(a5)                    ; 00FACC: 1b5c0001             
	subq.w #$1, d1                          ; 00FAD0: 5341                 
	bne.b PD68_Loop                         ; 00FAD2: 669a                 
	move.b #$27, (a5)                       ; 00FAD4: 1abc0027             
	mulu.w d7, d7                           ; 00FAD8: cec7                 
	move.b #$3F, $1(a5)                     ; 00FADA: 1b7c003f0001         
	move.w #$0, Z80_BUSREQ.l                ; 00FAE0: 33fc000000a11100     
	rts                                     ; 00FAE8: 4e75                 

PauseSound:
	bsr.w Z80_RequestBus                    ; 00FAEA: 6100f592             
	move.w d0, -(a7)                        ; 00FAEE: 3f00                 
	move.b #$FF, d0                         ; 00FAF0: 103c00ff             
	bra.b SetPause                          ; 00FAF4: 6008                 

ResumeSound:
	bsr.w Z80_RequestBus                    ; 00FAF6: 6100f586             
	move.w d0, -(a7)                        ; 00FAFA: 3f00                 
	clr.w d0                                ; 00FAFC: 4240                 

SetPause:
	move.b d0, Z80_PauseReq.l               ; 00FAFE: 13c000a009f1         PauseReq ($FF paused / 0 run)
	move.w (a7)+, d0                        ; 00FB04: 301f                 
	move.w #$0, Z80_BUSREQ.l                ; 00FB06: 33fc000000a11100     
	rts                                     ; 00FB0E: 4e75                 
	rts                                     ; 00FB10: 4e75                 
	rts                                     ; 00FB12: 4e75                 
