; Strider II (E) - 68000 side of the Tiertex sound engine (+ speech unpacker)
; capstone disassembly, labels/comments added. Data tables are described in Tiertex_SoundEngine.md
; Z80 driver image $327D8-$32F13 is disassembled separately (Strider2_Z80_driver.asm)


;==============================================================================
; VBlank excerpt: music cue -> SFX
;==============================================================================

; Part of VBlank: if the song has a cue list and the Z80 set $FFFFFF (cmd F4), play the next SFX from the list
VBlank_MusicCue:
	move.w #$1, $FFE044.l                   ; 000246: 33fc000100ffe044     
	tst.w $FFF5F4.l                         ; 00024E: 4a7900fff5f4         
	beq.w $2A0                              ; 000254: 6700004a             
	tst.b $FFFF.w                           ; 000258: 4a38ffff             Z80 cmd F4 sets $FFFFFF
	beq.w $2A0                              ; 00025C: 67000042             
	movem.l d0-d7/a0-a6, -(a7)              ; 000260: 48e7fffe             
	move.w $FFF5F6.l, d0                    ; 000264: 303900fff5f6         
	add.w d0, d0                            ; 00026A: d040                 
	movea.l $FFF5F8.l, a0                   ; 00026C: 207900fff5f8         
	cmpi.w #$FFFF, (a0, d0.w)               ; 000272: 0c70ffff0000         $FFFF terminates -> wrap to start
	bne.w VBC_Play                          ; 000278: 6600000c             
	move.w #$0, d0                          ; 00027C: 303c0000             
	move.w d0, $FFF5F6.l                    ; 000280: 33c000fff5f6         

VBC_Play:
	move.w (a0, d0.w), d0                   ; 000286: 30300000             
	jsr PlaySFX_NoCheck.l                   ; 00028A: 4eb900033030         
	addq.w #$1, $FFF5F6.l                   ; 000290: 527900fff5f6         
	movem.l (a7)+, d0-d7/a0-a6              ; 000296: 4cdf7fff             
	move.b #$0, $FFFF.w                     ; 00029A: 11fc0000ffff         acknowledge

;==============================================================================
; Driver loader
;==============================================================================

; Request Z80 bus and wait for grant
Z80_RequestBus:
	move.w #$100, Z80_BUSREQ.l              ; 03278A: 33fc010000a11100     
	btst.b #$0, Z80_BUSREQ.l                ; 032792: 0839000000a11100     
	bne.b Z80_RequestBus                    ; 03279A: 66ee                 
	rts                                     ; 03279C: 4e75                 

; Reset Z80, copy driver ($73C bytes) to Z80 $0000, run
LoadSoundDriver:
	move.w #$100, Z80_RESET.l               ; 03279E: 33fc010000a11200     
	bsr.b Z80_RequestBus                    ; 0327A6: 61e2                 
	lea.l Z80_RAM.l, a0                     ; 0327A8: 41f900a00000         Z80 RAM
	lea.l Z80_DriverImage.l, a1             ; 0327AE: 43f9000327d8         
	move.w #$73B, d7                        ; 0327B4: 3e3c073b             $73C bytes

loc_0327B8:
	move.b (a1)+, (a0)+                     ; 0327B8: 10d9                 
	dbra d7, loc_0327B8                     ; 0327BA: 51cffffc             
	move.w #$0, Z80_RESET.l                 ; 0327BE: 33fc000000a11200     
	move.w #$0, Z80_BUSREQ.l                ; 0327C6: 33fc000000a11100     
	move.w #$100, Z80_RESET.l               ; 0327CE: 33fc010000a11200     
	rts                                     ; 0327D6: 4e75                 

;==============================================================================
; Sound API
;==============================================================================

; a1 = source, d7 = size-1 -> Z80 $0A00
LoadVoiceBank:
	lea.l Z80_VoiceBank.l, a2               ; 032F14: 45f900a00a00         

loc_032F1A:
	move.b (a1)+, (a2)+                     ; 032F1A: 14d9                 
	dbra d7, loc_032F1A                     ; 032F1C: 51cffffc             
	rts                                     ; 032F20: 4e75                 
	rts                                     ; 032F22: 4e75                 

; d0.w = song number (0 = silence)
PlayMusic:
	bsr.w Z80_RequestBus                    ; 032F24: 6100f864             
	move.b #$0, $FFFFFF.l                   ; 032F28: 13fc000000ffffff     clear cue flag
	move.w #$0, $FFF5F4.l                   ; 032F30: 33fc000000fff5f4     
	move.l #$0, $FFF5F8.l                   ; 032F38: 23fc0000000000fff5f8 
	move.w #$0, $FFF5F6.l                   ; 032F42: 33fc000000fff5f6     
	move.b #$0, Z80_DAC_HalfVol.l           ; 032F4A: 13fc000000a009e4     DAC half volume off
	tst.w d0                                ; 032F52: 4a40                 
	beq.w PM_CopyTracks                     ; 032F54: 6700003e             
	move.w d0, d1                           ; 032F58: 3200                 
	subq.w #$1, d1                          ; 032F5A: 5341                 
	add.w d1, d1                            ; 032F5C: d241                 
	move.w d1, d2                           ; 032F5E: 3401                 
	add.w d1, d1                            ; 032F60: d241                 
	add.w d1, d1                            ; 032F62: d241                 
	add.w d2, d1                            ; 032F64: d242                 
	lea.l SongExtTable.l, a5                ; 032F66: 4bf90003372c         SongExtTable + (song-1)*10
	move.l (a5, d1.w), d2                   ; 032F6C: 24351000             cue list pointer (0 = none)
	beq.w PM_Voices                         ; 032F70: 67000018             
	move.l d2, $FFF5F8.l                    ; 032F74: 23c200fff5f8         
	move.w #$1, $FFF5F4.l                   ; 032F7A: 33fc000100fff5f4     
	move.b #$1, Z80_DAC_HalfVol.l           ; 032F82: 13fc000100a009e4     music playing -> DAC at half volume

PM_Voices:
	movea.l $4(a5, d1.w), a1                ; 032F8A: 22751004             voice bank pointer
	move.w $8(a5, d1.w), d7                 ; 032F8E: 3e351008             voice bank size-1
	bsr.b LoadVoiceBank                     ; 032F92: 6180                 

PM_CopyTracks:
	lea.l Z80_SongData.l, a5                ; 032F94: 4bf900a00e00         
	lea.l SongTable.l, a0                   ; 032F9A: 41f900033480         SongTable + song*36
	lsl.w #$2, d0                           ; 032FA0: e548                 
	adda.w d0, a0                           ; 032FA2: d0c0                 
	lsl.w #$3, d0                           ; 032FA4: e748                 
	adda.w d0, a0                           ; 032FA6: d0c0                 
	lea.l $18(a0), a3                       ; 032FA8: 47e80018             
	lea.l $32766(pc), a2                    ; 032FAC: 45faf7b8             
	moveq #$28, d7                          ; 032FB0: 7e28                 
	lea.l Z80_Mus_FM1.l, a4                 ; 032FB2: 49f900a00800         
	bsr.w PM_CopyTrack                      ; 032FB8: 61000034             
	lea.l $30(a4), a4                       ; 032FBC: 49ec0030             
	bsr.w PM_CopyTrack                      ; 032FC0: 6100002c             
	lea.l $30(a4), a4                       ; 032FC4: 49ec0030             
	bsr.w PM_CopyTrack                      ; 032FC8: 61000024             
	lea.l $30(a4), a4                       ; 032FCC: 49ec0030             
	bsr.w PM_CopyTrack                      ; 032FD0: 6100001c             
	lea.l $30(a4), a4                       ; 032FD4: 49ec0030             
	bsr.w PM_CopyTrack                      ; 032FD8: 61000014             
	lea.l $30(a4), a4                       ; 032FDC: 49ec0030             
	bsr.w PM_CopyTrack                      ; 032FE0: 6100000c             
	move.w #$0, Z80_BUSREQ.l                ; 032FE4: 33fc000000a11100     
	rts                                     ; 032FEC: 4e75                 

; a0 -> ROM track pointer (0 = silent stub, <0 = leave channel), a3 -> length, a4 = Z80 track RAM, a5 = Z80 dest
PM_CopyTrack:
	movea.l a2, a1                          ; 032FEE: 224a                 
	move.l d7, d1                           ; 032FF0: 2207                 
	move.w (a3)+, d2                        ; 032FF2: 341b                 
	move.l (a0)+, d0                        ; 032FF4: 2018                 
	bmi.b PMCT_Skip                         ; 032FF6: 6b1e                 
	beq.b PMCT_Copy                         ; 032FF8: 6704                 
	movea.l d0, a1                          ; 032FFA: 2240                 
	move.w d2, d1                           ; 032FFC: 3202                 

PMCT_Copy:
	move.l a5, d0                           ; 032FFE: 200d                 
	move.b d0, $5(a4)                       ; 033000: 19400005             
	lsr.w #$8, d0                           ; 033004: e048                 
	move.b d0, $6(a4)                       ; 033006: 19400006             
	subq.w #$1, d1                          ; 03300A: 5341                 
	bsr.w CopyBytes                         ; 03300C: 6100000e             
	move.b #$1, $7(a4)                      ; 033010: 197c00010007         

PMCT_Skip:
	rts                                     ; 033016: 4e75                 

CopySFX256:
	move.w #$FF, d1                         ; 033018: 323c00ff             

CopyBytes:
	move.b (a1)+, (a5)+                     ; 03301C: 1ad9                 
	dbra d1, CopyBytes                      ; 03301E: 51c9fffc             
	rts                                     ; 033022: 4e75                 

; d0.w = SFX id (bits 0-11) | forced channel (bits 12-15: 0 = auto, 3-6 = FM3-FM6). Ignored while $FFC192 set
PlaySFX:
	tst.w $FFC192.l                         ; 033024: 4a7900ffc192         sound effects disabled?
	beq.w PlaySFX_NoCheck                   ; 03302A: 67000004             
	rts                                     ; 03302E: 4e75                 

PlaySFX_NoCheck:
	movem.l d0-d7/a0-a5, -(a7)              ; 033030: 48e7fffc             
	move.w d0, d1                           ; 033034: 3200                 
	andi.w #$FFF, d0                        ; 033036: 02400fff             
	cmpi.w #$40, d0                         ; 03303A: 0c400040             ids >= $40 ignored
	bcs.b PSFX_Valid                        ; 03303E: 6504                 
	bra.w PSFX_Exit                         ; 033040: 600001de             

PSFX_Valid:
	eor.w d0, d1                            ; 033044: b141                 
	rol.w #$4, d1                           ; 033046: e959                 
	bsr.w Z80_RequestBus                    ; 033048: 6100f740             
	move.w $FFF390.l, $FFF392.l             ; 03304C: 33f900fff39000fff392 
	move.w d0, $FFF390.l                    ; 033056: 33c000fff390         
	lea.l SfxTable.l, a0                    ; 03305C: 41f9000337e8         SfxTable
	lsl.w #$2, d0                           ; 033062: e548                 
	movea.l (a0, d0.w), a1                  ; 033064: 22700000             
	move.b (a0, d0.w), d0                   ; 033068: 10300000             
	beq.w PSFX_FM                           ; 03306C: 670000a8             
	move.l a1, d2                           ; 033070: 2409                 
	lea.l DacTable.l, a1                    ; 033072: 43f9000338e8         DacTable
	andi.w #$FF, d0                         ; 033078: 024000ff             
	lsl.w #$2, d0                           ; 03307C: e548                 
	move.w (a1, d0.w), d4                   ; 03307E: 38310000             
	move.w $2(a1, d0.w), d3                 ; 033082: 36310002             
	neg.w d4                                ; 033086: 4444                 
	andi.l #$FFFFFF, d2                     ; 033088: 028200ffffff         
	movea.l d2, a1                          ; 03308E: 2242                 
	move.w #$F, d5                          ; 033090: 3a3c000f             
	lsr.l d5, d2                            ; 033094: eaaa                 
	move.b d2, d5                           ; 033096: 1a02                 
	lsr.w #$8, d2                           ; 033098: e04a                 
	move.b d5, Z80_DAC_Bank.l               ; 03309A: 13c500a009fc         
	move.b d2, Z80_DAC_Bank+1.l             ; 0330A0: 13c200a009fd         DAC_Bank (trigger)
	tst.w d4                                ; 0330A6: 4a44                 
	bpl.b loc_0330B0                        ; 0330A8: 6a06                 
	clr.b d2                                ; 0330AA: 4202                 
	clr.b d5                                ; 0330AC: 4205                 
	neg.w d4                                ; 0330AE: 4444                 

loc_0330B0:
	move.b d5, Z80_DAC_LoopBank.l           ; 0330B0: 13c500a009fe         DAC_LoopBank (cleared again at $331DC)
	move.l a1, d2                           ; 0330B6: 2409                 
	andi.w #$7FFF, d2                       ; 0330B8: 02427fff             
	ori.w #$8000, d2                        ; 0330BC: 00428000             
	move.b d2, Z80_DAC_Addr.l               ; 0330C0: 13c200a009f8         
	lsr.w #$8, d2                           ; 0330C6: e04a                 
	move.b d2, Z80_DAC_Addr+1.l             ; 0330C8: 13c200a009f9         
	move.b d4, Z80_DAC_Len.l                ; 0330CE: 13c400a009fa         
	lsr.w #$8, d4                           ; 0330D4: e04c                 
	move.b d4, Z80_DAC_Len+1.l              ; 0330D6: 13c400a009fb         
	move.l #$CE2A, d4                       ; 0330DC: 283c0000ce2a         TA = $400 - 52778/rate
	divu.w d3, d4                           ; 0330E2: 88c3                 
	move.w #$400, d3                        ; 0330E4: 363c0400             
	sub.w d4, d3                            ; 0330E8: 9644                 
	move.w d3, d4                           ; 0330EA: 3803                 
	andi.w #$3, d4                          ; 0330EC: 02440003             
	move.b d4, Z80_DAC_TimerA.l             ; 0330F0: 13c400a009f6         
	lsr.w #$2, d3                           ; 0330F6: e44b                 
	move.b d3, Z80_DAC_TimerA+1.l           ; 0330F8: 13c300a009f7         
	lea.l $32766(pc), a1                    ; 0330FE: 43faf666             
	move.w #$0, d1                          ; 033102: 323c0000             
	lea.l Z80_SFX_FM6.l, a0                 ; 033106: 41f900a009b0         
	lea.l Z80_SfxSlotFM6.l, a5              ; 03310C: 4bf900a01e00         
	bra.w PSFX_Start                        ; 033112: 600000a8             

; FM SFX: choose channel. Auto order FM6, FM4, FM3, FM5; drop SFX if all busy
PSFX_FM:
	tst.w d1                                ; 033116: 4a41                 
	beq.b PSFX_Auto                         ; 033118: 6718                 
	cmpi.w #$6, d1                          ; 03311A: 0c410006             
	beq.b PSFX_Ch6                          ; 03311E: 6766                 
	cmpi.w #$5, d1                          ; 033120: 0c410005             
	beq.b PSFX_Ch5                          ; 033124: 676e                 
	cmpi.w #$4, d1                          ; 033126: 0c410004             
	beq.b PSFX_Ch4                          ; 03312A: 6776                 
	cmpi.w #$3, d1                          ; 03312C: 0c410003             
	beq.b PSFX_Ch3                          ; 033130: 677e                 

PSFX_Auto:
	lea.l Z80_SFX_FM6.l, a0                 ; 033132: 41f900a009b0         
	lea.l Z80_SfxSlotFM6.l, a5              ; 033138: 4bf900a01e00         
	move.b (a0), d0                         ; 03313E: 1010                 
	or.b $1(a0), d0                         ; 033140: 80280001             
	beq.b PSFX_Start                        ; 033144: 6776                 
	lea.l Z80_SFX_FM4.l, a0                 ; 033146: 41f900a00950         
	lea.l Z80_SfxSlotFM4.l, a5              ; 03314C: 4bf900a01c00         
	move.b (a0), d0                         ; 033152: 1010                 
	or.b $1(a0), d0                         ; 033154: 80280001             
	beq.b PSFX_Start                        ; 033158: 6762                 
	lea.l Z80_SFX_FM3.l, a0                 ; 03315A: 41f900a00920         
	lea.l Z80_SfxSlotFM3.l, a5              ; 033160: 4bf900a01b00         
	move.b (a0), d0                         ; 033166: 1010                 
	or.b $1(a0), d0                         ; 033168: 80280001             
	beq.b PSFX_Start                        ; 03316C: 674e                 
	lea.l Z80_SFX_FM5.l, a0                 ; 03316E: 41f900a00980         
	lea.l Z80_SfxSlotFM5.l, a5              ; 033174: 4bf900a01d00         
	move.b (a0), d0                         ; 03317A: 1010                 
	or.b $1(a0), d0                         ; 03317C: 80280001             
	beq.b PSFX_Start                        ; 033180: 673a                 
	bra.w PSFX_Release                      ; 033182: 60000094             

PSFX_Ch6:
	lea.l Z80_SFX_FM6.l, a0                 ; 033186: 41f900a009b0         
	lea.l Z80_SfxSlotFM6.l, a5              ; 03318C: 4bf900a01e00         
	bra.b PSFX_Start                        ; 033192: 6028                 

PSFX_Ch5:
	lea.l Z80_SFX_FM5.l, a0                 ; 033194: 41f900a00980         
	lea.l Z80_SfxSlotFM5.l, a5              ; 03319A: 4bf900a01d00         
	bra.b PSFX_Start                        ; 0331A0: 601a                 

PSFX_Ch4:
	lea.l Z80_SFX_FM4.l, a0                 ; 0331A2: 41f900a00950         
	lea.l Z80_SfxSlotFM4.l, a5              ; 0331A8: 4bf900a01c00         
	bra.b PSFX_Start                        ; 0331AE: 600c                 

PSFX_Ch3:
	lea.l Z80_SFX_FM3.l, a0                 ; 0331B0: 41f900a00920         
	lea.l Z80_SfxSlotFM3.l, a5              ; 0331B6: 4bf900a01b00         

; Copy 256 bytes of SFX data to the channel slot, clear freq base & loop bank, set start request
PSFX_Start:
	move.l a5, d0                           ; 0331BC: 200d                 
	move.b d0, $5(a0)                       ; 0331BE: 11400005             
	lsr.w #$8, d0                           ; 0331C2: e048                 
	move.b d0, $6(a0)                       ; 0331C4: 11400006             
	bsr.w CopySFX256                        ; 0331C8: 6100fe4e             
	move.b #$0, d0                          ; 0331CC: 103c0000             
	move.b #$0, d1                          ; 0331D0: 123c0000             
	move.b d0, $11(a0)                      ; 0331D4: 11400011             
	move.b d1, $12(a0)                      ; 0331D8: 11410012             
	clr.b Z80_DAC_LoopBank.l                ; 0331DC: 423900a009fe         
	clr.b Z80_DAC_LoopBank+1.l              ; 0331E2: 423900a009ff         
	cmpi.w #$1, $FFF390.l                   ; 0331E8: 0c79000100fff390     SFX 1 "Bubble Bubble": patch its volume
	bne.w PSFX_Go                           ; 0331F0: 66000020             
	lea.l Z80_SfxSlotFM5.l, a5              ; 0331F4: 4bf900a01d00         
	move.b $FFC194.l, d0                    ; 0331FA: 103900ffc194         op4 TL (volume) of its inline voice = min($FFC194 + 2, $63), patched in the FM5 slot only
	addi.b #$2, d0                          ; 033200: 06000002             
	cmpi.b #$63, d0                         ; 033204: 0c000063             
	bcs.b loc_03320E                        ; 033208: 6504                 
	move.b #$63, d0                         ; 03320A: 103c0063             

loc_03320E:
	move.b d0, $9(a5)                       ; 03320E: 1b400009             

PSFX_Go:
	move.b #$1, $7(a0)                      ; 033212: 117c00010007         

PSFX_Release:
	move.w #$0, Z80_BUSREQ.l                ; 033218: 33fc000000a11100     

PSFX_Exit:
	movem.l (a7)+, d0-d7/a0-a5              ; 033220: 4cdf3fff             
	rts                                     ; 033224: 4e75                 

; Speech: 68k-timed DAC playback, Z80 held. a4 = data, d1.w = length, d3.w = rate (Hz). START (pad 1) aborts
PlayDAC_68k:
	bsr.w Z80_RequestBus                    ; 033226: 6100f562             
	move.w #$0, $FFE42A.l                   ; 03322A: 33fc000000ffe42a     
	lea.l YM2612.l, a5                      ; 033232: 4bf900a04000         
	move.b #$27, (a5)                       ; 033238: 1abc0027             
	lsl.l #$8, d7                           ; 03323C: e18f                 
	move.b #$15, $1(a5)                     ; 03323E: 1b7c00150001         
	lsl.l #$8, d7                           ; 033244: e18f                 
	lsl.l #$8, d7                           ; 033246: e18f                 
	lsl.l #$8, d7                           ; 033248: e18f                 
	lsl.l #$8, d7                           ; 03324A: e18f                 
	move.l #$CE2A, d4                       ; 03324C: 283c0000ce2a         TA = $400 - 52778/rate
	divu.w d3, d4                           ; 033252: 88c3                 
	move.w #$400, d3                        ; 033254: 363c0400             
	sub.w d4, d3                            ; 033258: 9644                 
	move.w d3, d4                           ; 03325A: 3803                 
	andi.w #$3, d4                          ; 03325C: 02440003             
	lsr.w #$2, d3                           ; 033260: e44b                 
	move.b #$24, (a5)                       ; 033262: 1abc0024             
	lsl.l #$8, d7                           ; 033266: e18f                 
	move.b d3, $1(a5)                       ; 033268: 1b430001             
	lsl.l #$8, d7                           ; 03326C: e18f                 
	lsl.l #$8, d7                           ; 03326E: e18f                 
	lsl.l #$8, d7                           ; 033270: e18f                 
	lsl.l #$8, d7                           ; 033272: e18f                 
	move.b #$25, (a5)                       ; 033274: 1abc0025             
	lsl.l #$8, d7                           ; 033278: e18f                 
	move.b d4, $1(a5)                       ; 03327A: 1b440001             
	lsl.l #$8, d7                           ; 03327E: e18f                 
	lsl.l #$8, d7                           ; 033280: e18f                 
	lsl.l #$8, d7                           ; 033282: e18f                 
	lsl.l #$8, d7                           ; 033284: e18f                 

PD68_Loop:
	move.b #$27, (a5)                       ; 033286: 1abc0027             

PD68_WaitBusy:
	move.b (a5), d0                         ; 03328A: 1015                 
	btst.b #$7, d0                          ; 03328C: 08000007             
	bne.b PD68_WaitBusy                     ; 033290: 66f8                 

PD68_WaitTA:
	move.b (a5), d0                         ; 033292: 1015                 
	andi.b #$1, d0                          ; 033294: 02000001             
	beq.b PD68_WaitTA                       ; 033298: 67f8                 
	move.b #$1F, $1(a5)                     ; 03329A: 1b7c001f0001         
	tst.w $FFE42A.l                         ; 0332A0: 4a7900ffe42a         
	bne.w PD68_Write                        ; 0332A6: 6600007c             
	move.w #$1, $FFE42A.l                   ; 0332AA: 33fc000100ffe42a     
	move.b #$2B, (a5)                       ; 0332B2: 1abc002b             
	move.b #$40, $A10009.l                  ; 0332B6: 13fc004000a10009     read pad 1 / pad 2 between samples
	move.b #$80, $1(a5)                     ; 0332BE: 1b7c00800001         
	move.b #$0, $A10003.l                   ; 0332C4: 13fc000000a10003     
	move.b #$40, $A1000B.l                  ; 0332CC: 13fc004000a1000b     
	move.b #$0, $A10005.l                   ; 0332D4: 13fc000000a10005     
	move.b $A10003.l, d0                    ; 0332DC: 103900a10003         
	move.b #$40, $A10003.l                  ; 0332E2: 13fc004000a10003     
	move.b #$B6, $2(a5)                     ; 0332EA: 1b7c00b60002         
	move.b $A10005.l, d2                    ; 0332F0: 143900a10005         
	move.b #$40, $A10005.l                  ; 0332F6: 13fc004000a10005     
	move.b #$C0, $3(a5)                     ; 0332FE: 1b7c00c00003         
	move.b $A10003.l, d6                    ; 033304: 1c3900a10003         
	andi.b #$30, d0                         ; 03330A: 02000030             
	andi.b #$30, d2                         ; 03330E: 02020030             
	move.b $A10005.l, d3                    ; 033312: 163900a10005         
	andi.b #$3F, d6                         ; 033318: 0206003f             
	andi.b #$3F, d3                         ; 03331C: 0203003f             
	lsl.b #$2, d0                           ; 033320: e508                 
	lsl.b #$2, d2                           ; 033322: e50a                 

PD68_Write:
	move.b #$2A, (a5)                       ; 033324: 1abc002a             
	move.b (a4)+, $1(a5)                    ; 033328: 1b5c0001             
	move.b #$0, $A10003.l                   ; 03332C: 13fc000000a10003     
	move.b #$40, $A1000B.l                  ; 033334: 13fc004000a1000b     
	move.b #$0, $A10005.l                   ; 03333C: 13fc000000a10005     
	move.b $A10003.l, d0                    ; 033344: 103900a10003         
	move.b #$40, $A10003.l                  ; 03334A: 13fc004000a10003     
	move.b $A10005.l, d2                    ; 033352: 143900a10005         
	move.b #$40, $A10005.l                  ; 033358: 13fc004000a10005     
	move.b $A10003.l, d6                    ; 033360: 1c3900a10003         
	andi.b #$30, d0                         ; 033366: 02000030             
	andi.b #$30, d2                         ; 03336A: 02020030             
	move.b $A10005.l, d3                    ; 03336E: 163900a10005         
	andi.b #$3F, d6                         ; 033374: 0206003f             
	andi.b #$3F, d3                         ; 033378: 0203003f             
	lsl.b #$2, d0                           ; 03337C: e508                 
	lsl.b #$2, d2                           ; 03337E: e50a                 
	or.b d6, d0                             ; 033380: 8006                 
	or.b d3, d2                             ; 033382: 8403                 
	not.b d0                                ; 033384: 4600                 
	not.b d2                                ; 033386: 4602                 
	move.b d0, $FFE03F.l                    ; 033388: 13c000ffe03f         store pad state
	btst.b #$7, d0                          ; 03338E: 08000007             START pressed -> stop
	bne.w PD68_End                          ; 033392: 66000008             
	subq.w #$1, d1                          ; 033396: 5341                 
	bne.w PD68_Loop                         ; 033398: 6600feec             

PD68_End:
	move.b #$27, (a5)                       ; 03339C: 1abc0027             
	mulu.w d7, d7                           ; 0333A0: cec7                 
	move.b #$3F, $1(a5)                     ; 0333A2: 1b7c003f0001         
	move.w #$0, Z80_BUSREQ.l                ; 0333A8: 33fc000000a11100     
	rts                                     ; 0333B0: 4e75                 

; Loop (with VSync) while any music track is active; START aborts
WaitMusicEnd:
	bsr.w Z80_RequestBus                    ; 0333B2: 6100f3d6             
	tst.b Z80_Mus_FM1.l                     ; 0333B6: 4a3900a00800         
	bne.w WME_Busy                          ; 0333BC: 6600007a             
	tst.b Z80_Mus_FM1+1.l                   ; 0333C0: 4a3900a00801         
	bne.w WME_Busy                          ; 0333C6: 66000070             
	tst.b Z80_Mus_FM2.l                     ; 0333CA: 4a3900a00830         
	bne.w WME_Busy                          ; 0333D0: 66000066             
	tst.b Z80_Mus_FM2+1.l                   ; 0333D4: 4a3900a00831         
	bne.w WME_Busy                          ; 0333DA: 6600005c             
	tst.b Z80_Mus_FM3.l                     ; 0333DE: 4a3900a00860         
	bne.w WME_Busy                          ; 0333E4: 66000052             
	tst.b Z80_Mus_FM3+1.l                   ; 0333E8: 4a3900a00861         
	bne.w WME_Busy                          ; 0333EE: 66000048             
	tst.b Z80_Mus_FM4.l                     ; 0333F2: 4a3900a00890         
	bne.w WME_Busy                          ; 0333F8: 6600003e             
	tst.b Z80_Mus_FM4+1.l                   ; 0333FC: 4a3900a00891         
	bne.w WME_Busy                          ; 033402: 66000034             
	tst.b Z80_Mus_FM5.l                     ; 033406: 4a3900a008c0         
	bne.w WME_Busy                          ; 03340C: 6600002a             
	tst.b Z80_Mus_FM5+1.l                   ; 033410: 4a3900a008c1         
	bne.w WME_Busy                          ; 033416: 66000020             
	tst.b Z80_Mus_FM6.l                     ; 03341A: 4a3900a008f0         
	bne.w WME_Busy                          ; 033420: 66000016             
	tst.b Z80_Mus_FM6+1.l                   ; 033424: 4a3900a008f1         
	bne.w WME_Busy                          ; 03342A: 6600000c             
	move.w #$0, Z80_BUSREQ.l                ; 03342E: 33fc000000a11100     

WME_Ret:
	rts                                     ; 033436: 4e75                 

WME_Busy:
	move.w #$0, Z80_BUSREQ.l                ; 033438: 33fc000000a11100     
	jsr $170E.l                             ; 033440: 4eb90000170e         
	jsr $BBB2.l                             ; 033446: 4eb90000bbb2         
	btst.b #$7, $FFE03F.l                   ; 03344C: 0839000700ffe03f     
	bne.b WME_Ret                           ; 033454: 66e0                 
	bra.w WaitMusicEnd                      ; 033456: 6000ff5a             

PauseSound:
	bsr.w Z80_RequestBus                    ; 03345A: 6100f32e             
	move.w d0, -(a7)                        ; 03345E: 3f00                 
	move.b #$FF, d0                         ; 033460: 103c00ff             
	bra.b SetPause                          ; 033464: 6008                 

ResumeSound:
	bsr.w Z80_RequestBus                    ; 033466: 6100f322             
	move.w d0, -(a7)                        ; 03346A: 3f00                 
	clr.w d0                                ; 03346C: 4240                 

SetPause:
	move.b d0, Z80_PauseReq.l               ; 03346E: 13c000a009f1         
	move.w (a7)+, d0                        ; 033474: 301f                 
	move.w #$0, Z80_BUSREQ.l                ; 033476: 33fc000000a11100     
	rts                                     ; 03347E: 4e75                 

;==============================================================================
; Speech loader
;==============================================================================

; d0.w = speech number. Unpack sample to RAM $FF0002, length -> $FFF396, rate -> $FFF394
LoadSpeech:
	lea.l SpeechTable.l, a0                 ; 0039E8: 41f900003aaa         
	add.w d0, d0                            ; 0039EE: d040                 
	move.w d0, d1                           ; 0039F0: 3200                 
	add.w d0, d0                            ; 0039F2: d040                 
	add.w d1, d0                            ; 0039F4: d041                 
	tst.l (a0, d0.w)                        ; 0039F6: 4ab00000             
	bne.w LS_Packed                         ; 0039FA: 66000050             
	move.w $4(a0, d0.w), d0                 ; 0039FE: 30300004             
	lea.l SfxTable.l, a0                    ; 003A02: 41f9000337e8         entry 0 pointer: take an uncompressed DAC sample via the SFX table
	add.w d0, d0                            ; 003A08: d040                 
	add.w d0, d0                            ; 003A0A: d040                 
	move.l (a0, d0.w), d1                   ; 003A0C: 22300000             
	move.l d1, d2                           ; 003A10: 2401                 
	andi.l #$FFFFFF, d2                     ; 003A12: 028200ffffff         
	movea.l d2, a1                          ; 003A18: 2242                 
	rol.l #$8, d1                           ; 003A1A: e199                 
	andi.w #$FF, d1                         ; 003A1C: 024100ff             
	add.w d1, d1                            ; 003A20: d241                 
	add.w d1, d1                            ; 003A22: d241                 
	lea.l DacTable.l, a0                    ; 003A24: 41f9000338e8         
	move.w $2(a0, d1.w), $FFF394.l          ; 003A2A: 33f0100200fff394     rate
	move.w (a0, d1.w), d0                   ; 003A32: 30301000             
	move.w d0, $FFF396.l                    ; 003A36: 33c000fff396         length
	lea.l $FF0002.l, a0                     ; 003A3C: 41f900ff0002         

loc_003A42:
	move.b (a1)+, (a0)+                     ; 003A42: 10d9                 
	dbra d0, loc_003A42                     ; 003A44: 51c8fffc             
	bra.w LS_Done                           ; 003A48: 6000005e             

LS_Packed:
	move.w $4(a0, d0.w), $FFF394.l          ; 003A4C: 33f0000400fff394     
	move.l (a0, d0.w), d2                   ; 003A54: 24300000             
	btst.b #$1F, d2                         ; 003A58: 0802001f             bit 31 set -> nibble-interleaved Huffman
	beq.w LS_ByteHuff                       ; 003A5C: 67000014             
	andi.l #$7FFFFFFF, d2                   ; 003A60: 02827fffffff         
	movea.l d2, a0                          ; 003A66: 2042                 
	jsr HuffN_Unpack.l                      ; 003A68: 4eb90000bfa6         
	bra.w LS_Delta                          ; 003A6E: 6000000a             

LS_ByteHuff:
	movea.l d2, a0                          ; 003A72: 2042                 
	jsr Huff_Unpack.l                       ; 003A74: 4eb90000be70         

; Integrate deltas: acc += b[n]; out[n] = acc*4 (8-bit wrap), in place from $FF0002
LS_Delta:
	lea.l $FF0000.l, a1                     ; 003A7A: 43f900ff0000         
	move.w (a1)+, d7                        ; 003A80: 3e19                 
	subq.w #$2, d7                          ; 003A82: 5547                 
	move.b (a1), d0                         ; 003A84: 1011                 
	move.b d0, d2                           ; 003A86: 1400                 
	add.b d2, d2                            ; 003A88: d402                 
	add.b d2, d2                            ; 003A8A: d402                 
	move.b d2, (a1)+                        ; 003A8C: 12c2                 

LS_DeltaLoop:
	move.b (a1), d1                         ; 003A8E: 1211                 
	add.b d1, d0                            ; 003A90: d001                 
	move.b d0, d2                           ; 003A92: 1400                 
	add.b d2, d2                            ; 003A94: d402                 
	add.b d2, d2                            ; 003A96: d402                 
	move.b d2, (a1)+                        ; 003A98: 12c2                 
	dbra d7, LS_DeltaLoop                   ; 003A9A: 51cffff2             
	move.w $FF0000.l, $FFF396.l             ; 003A9E: 33f900ff000000fff396 decoded length word

LS_Done:
	rts                                     ; 003AA8: 4e75                 

;==============================================================================
; Huffman tree builder (byte format)
;==============================================================================

; Recursive: bit 0 = leaf (word $00xx from leaf list a3), bit 1 = node (word = -(offset to right child)+2), LSB-first bits from a5
Huff_BuildTree:
	addq.w #$1, d7                          ; 00BCAC: 5247                 
	cmpi.w #$8, d7                          ; 00BCAE: 0c470008             
	blt.b HBT_Test                          ; 00BCB2: 6d04                 
	moveq #$0, d7                           ; 00BCB4: 7e00                 
	move.b (a5)+, d4                        ; 00BCB6: 181d                 

HBT_Test:
	btst.l d7, d4                           ; 00BCB8: 0f04                 
	bne.w HBT_Node                          ; 00BCBA: 66000008             
	clr.b (a2)+                             ; 00BCBE: 421a                 
	move.b (a3)+, (a2)+                     ; 00BCC0: 14db                 
	rts                                     ; 00BCC2: 4e75                 

HBT_Node:
	move.l a2, -(a7)                        ; 00BCC4: 2f0a                 
	addq.l #$2, a2                          ; 00BCC6: 548a                 
	bsr.b Huff_BuildTree                    ; 00BCC8: 61e2                 
	movea.l (a7)+, a4                       ; 00BCCA: 285f                 
	move.l a2, d3                           ; 00BCCC: 260a                 
	sub.l a4, d3                            ; 00BCCE: 968c                 
	neg.w d3                                ; 00BCD0: 4443                 
	addq.w #$2, d3                          ; 00BCD2: 5443                 
	move.w d3, (a4)                         ; 00BCD4: 3883                 
	bsr.b Huff_BuildTree                    ; 00BCD6: 61d4                 
	rts                                     ; 00BCD8: 4e75                 

;==============================================================================
; Huffman unpacker (byte format)
;==============================================================================

; Byte format: a0+0 tree bits, a0+$40 leaves, a0+$140 count.l, a0+$148 data. Output $FF0000
Huff_Unpack:
	lea.l $FF0000.l, a1                     ; 00BE70: 43f900ff0000         
	lea.l $FFE47A.l, a2                     ; 00BE76: 45f900ffe47a         
	move.l a2, d2                           ; 00BE7C: 240a                 
	lea.l $40(a0), a3                       ; 00BE7E: 47e80040             
	moveq #$7, d7                           ; 00BE82: 7e07                 
	movea.l a0, a5                          ; 00BE84: 2a48                 
	bsr.w Huff_BuildTree                    ; 00BE86: 6100fe24             
	move.l $140(a0), d0                     ; 00BE8A: 20280140             
	move.l d0, $FFE472.l                    ; 00BE8E: 23c000ffe472         
	move.l d0, d1                           ; 00BE94: 2200                 
	moveq #$0, d7                           ; 00BE96: 7e00                 
	move.w #$1, d5                          ; 00BE98: 3a3c0001             
	lea.l $148(a0), a5                      ; 00BE9C: 4be80148             
	movea.l d2, a2                          ; 00BEA0: 2442                 

HU_NextByte:
	move.b (a5)+, d4                        ; 00BEA2: 181d                 

loc_00BEA4:
	move.w (a2)+, d3                        ; 00BEA4: 361a                 
	bpl.b loc_00BF02                        ; 00BEA6: 6a5a                 
	lsr.b #$1, d4                           ; 00BEA8: e20c                 
	bcc.b loc_00BEAE                        ; 00BEAA: 6402                 
	suba.w d3, a2                           ; 00BEAC: 94c3                 

loc_00BEAE:
	move.w (a2)+, d3                        ; 00BEAE: 361a                 
	bpl.b loc_00BF0C                        ; 00BEB0: 6a5a                 
	lsr.b #$1, d4                           ; 00BEB2: e20c                 
	bcc.b loc_00BEB8                        ; 00BEB4: 6402                 
	suba.w d3, a2                           ; 00BEB6: 94c3                 

loc_00BEB8:
	move.w (a2)+, d3                        ; 00BEB8: 361a                 
	bpl.w loc_00BF16                        ; 00BEBA: 6a00005a             
	lsr.b #$1, d4                           ; 00BEBE: e20c                 
	bcc.b loc_00BEC4                        ; 00BEC0: 6402                 
	suba.w d3, a2                           ; 00BEC2: 94c3                 

loc_00BEC4:
	move.w (a2)+, d3                        ; 00BEC4: 361a                 
	bpl.w loc_00BF20                        ; 00BEC6: 6a000058             
	lsr.b #$1, d4                           ; 00BECA: e20c                 
	bcc.b loc_00BED0                        ; 00BECC: 6402                 
	suba.w d3, a2                           ; 00BECE: 94c3                 

loc_00BED0:
	move.w (a2)+, d3                        ; 00BED0: 361a                 
	bpl.w loc_00BF2A                        ; 00BED2: 6a000056             
	lsr.b #$1, d4                           ; 00BED6: e20c                 
	bcc.b loc_00BEDC                        ; 00BED8: 6402                 
	suba.w d3, a2                           ; 00BEDA: 94c3                 

loc_00BEDC:
	move.w (a2)+, d3                        ; 00BEDC: 361a                 
	bpl.w loc_00BF34                        ; 00BEDE: 6a000054             
	lsr.b #$1, d4                           ; 00BEE2: e20c                 
	bcc.b loc_00BEE8                        ; 00BEE4: 6402                 
	suba.w d3, a2                           ; 00BEE6: 94c3                 

loc_00BEE8:
	move.w (a2)+, d3                        ; 00BEE8: 361a                 
	bpl.w loc_00BF3E                        ; 00BEEA: 6a000052             
	lsr.b #$1, d4                           ; 00BEEE: e20c                 
	bcc.b loc_00BEF4                        ; 00BEF0: 6402                 
	suba.w d3, a2                           ; 00BEF2: 94c3                 

loc_00BEF4:
	move.w (a2)+, d3                        ; 00BEF4: 361a                 
	bpl.w loc_00BF48                        ; 00BEF6: 6a000050             
	lsr.b #$1, d4                           ; 00BEFA: e20c                 
	bcc.b HU_NextByte                       ; 00BEFC: 64a4                 
	suba.w d3, a2                           ; 00BEFE: 94c3                 
	bra.b HU_NextByte                       ; 00BF00: 60a0                 

loc_00BF02:
	move.b d3, (a1)+                        ; 00BF02: 12c3                 
	movea.l d2, a2                          ; 00BF04: 2442                 
	dbra d0, loc_00BEA4                     ; 00BF06: 51c8ff9c             
	rts                                     ; 00BF0A: 4e75                 

loc_00BF0C:
	move.b d3, (a1)+                        ; 00BF0C: 12c3                 
	movea.l d2, a2                          ; 00BF0E: 2442                 
	dbra d0, loc_00BEAE                     ; 00BF10: 51c8ff9c             
	rts                                     ; 00BF14: 4e75                 

loc_00BF16:
	move.b d3, (a1)+                        ; 00BF16: 12c3                 
	movea.l d2, a2                          ; 00BF18: 2442                 
	dbra d0, loc_00BEB8                     ; 00BF1A: 51c8ff9c             
	rts                                     ; 00BF1E: 4e75                 

loc_00BF20:
	move.b d3, (a1)+                        ; 00BF20: 12c3                 
	movea.l d2, a2                          ; 00BF22: 2442                 
	dbra d0, loc_00BEC4                     ; 00BF24: 51c8ff9e             
	rts                                     ; 00BF28: 4e75                 

loc_00BF2A:
	move.b d3, (a1)+                        ; 00BF2A: 12c3                 
	movea.l d2, a2                          ; 00BF2C: 2442                 
	dbra d0, loc_00BED0                     ; 00BF2E: 51c8ffa0             
	rts                                     ; 00BF32: 4e75                 

loc_00BF34:
	move.b d3, (a1)+                        ; 00BF34: 12c3                 
	movea.l d2, a2                          ; 00BF36: 2442                 
	dbra d0, loc_00BEDC                     ; 00BF38: 51c8ffa2             
	rts                                     ; 00BF3C: 4e75                 

loc_00BF3E:
	move.b d3, (a1)+                        ; 00BF3E: 12c3                 
	movea.l d2, a2                          ; 00BF40: 2442                 
	dbra d0, loc_00BEE8                     ; 00BF42: 51c8ffa4             
	rts                                     ; 00BF46: 4e75                 

loc_00BF48:
	move.b d3, (a1)+                        ; 00BF48: 12c3                 
	movea.l d2, a2                          ; 00BF4A: 2442                 
	dbra d0, loc_00BEF4                     ; 00BF4C: 51c8ffa6             
	rts                                     ; 00BF50: 4e75                 

;==============================================================================
; Huffman tree builder + unpacker (nibble format)
;==============================================================================

; Nibble format bit reader: each byte = hi nibble of (a5) : hi nibble of 2(a5), a5 += 4
HuffN_BuildTree:
	addq.w #$1, d7                          ; 00BF52: 5247                 
	cmpi.w #$8, d7                          ; 00BF54: 0c470008             
	blt.b HNBT_Test                         ; 00BF58: 6d16                 
	moveq #$0, d7                           ; 00BF5A: 7e00                 
	move.b (a5), d4                         ; 00BF5C: 1815                 
	andi.b #$F0, d4                         ; 00BF5E: 020400f0             
	move.b $2(a5), d5                       ; 00BF62: 1a2d0002             
	andi.b #$F0, d5                         ; 00BF66: 020500f0             
	lsr.b #$4, d5                           ; 00BF6A: e80d                 
	or.b d5, d4                             ; 00BF6C: 8805                 
	addq.l #$4, a5                          ; 00BF6E: 588d                 

HNBT_Test:
	btst.l d7, d4                           ; 00BF70: 0f04                 
	bne.w HNBT_Node                         ; 00BF72: 6600001c             
	clr.b (a2)+                             ; 00BF76: 421a                 
	move.b (a3), d6                         ; 00BF78: 1c13                 
	andi.b #$F0, d6                         ; 00BF7A: 020600f0             
	move.b $2(a3), d5                       ; 00BF7E: 1a2b0002             
	andi.b #$F0, d5                         ; 00BF82: 020500f0             
	lsr.b #$4, d5                           ; 00BF86: e80d                 
	or.b d5, d6                             ; 00BF88: 8c05                 
	addq.l #$4, a3                          ; 00BF8A: 588b                 
	move.b d6, (a2)+                        ; 00BF8C: 14c6                 
	rts                                     ; 00BF8E: 4e75                 

HNBT_Node:
	move.l a2, -(a7)                        ; 00BF90: 2f0a                 
	addq.l #$2, a2                          ; 00BF92: 548a                 
	bsr.b HuffN_BuildTree                   ; 00BF94: 61bc                 
	movea.l (a7)+, a4                       ; 00BF96: 285f                 
	move.l a2, d3                           ; 00BF98: 260a                 
	sub.l a4, d3                            ; 00BF9A: 968c                 
	neg.w d3                                ; 00BF9C: 4443                 
	addq.w #$2, d3                          ; 00BF9E: 5443                 
	move.w d3, (a4)                         ; 00BFA0: 3883                 
	bsr.b HuffN_BuildTree                   ; 00BFA2: 61ae                 
	rts                                     ; 00BFA4: 4e75                 

; Nibble-interleaved format: tree a0+0, leaves a0+$100, count a0+$500 (8 nibbles), data a0+$520. Output $FF0000
HuffN_Unpack:
	lea.l $FF0000.l, a1                     ; 00BFA6: 43f900ff0000         
	lea.l $FFE47A.l, a2                     ; 00BFAC: 45f900ffe47a         
	move.l a2, d2                           ; 00BFB2: 240a                 
	move.w #$100, d1                        ; 00BFB4: 323c0100             
	lea.l (a0, d1.w), a3                    ; 00BFB8: 47f01000             
	moveq #$7, d7                           ; 00BFBC: 7e07                 
	movea.l a0, a5                          ; 00BFBE: 2a48                 
	bsr.b HuffN_BuildTree                   ; 00BFC0: 6190                 
	move.w #$500, d0                        ; 00BFC2: 303c0500             
	move.b (a0, d0.w), d1                   ; 00BFC6: 12300000             
	andi.l #$F0, d1                         ; 00BFCA: 0281000000f0         
	lsl.l #$4, d1                           ; 00BFD0: e989                 
	move.b $2(a0, d0.w), d7                 ; 00BFD2: 1e300002             
	andi.l #$F0, d7                         ; 00BFD6: 0287000000f0         
	or.l d7, d1                             ; 00BFDC: 8287                 
	lsl.l #$4, d1                           ; 00BFDE: e989                 
	move.b $4(a0, d0.w), d7                 ; 00BFE0: 1e300004             
	andi.l #$F0, d7                         ; 00BFE4: 0287000000f0         
	or.l d7, d1                             ; 00BFEA: 8287                 
	lsl.l #$4, d1                           ; 00BFEC: e989                 
	move.b $6(a0, d0.w), d7                 ; 00BFEE: 1e300006             
	andi.l #$F0, d7                         ; 00BFF2: 0287000000f0         
	or.l d7, d1                             ; 00BFF8: 8287                 
	lsl.l #$4, d1                           ; 00BFFA: e989                 
	move.b $8(a0, d0.w), d7                 ; 00BFFC: 1e300008             
	andi.l #$F0, d7                         ; 00C000: 0287000000f0         
	or.l d7, d1                             ; 00C006: 8287                 
	lsl.l #$4, d1                           ; 00C008: e989                 
	move.b $A(a0, d0.w), d7                 ; 00C00A: 1e30000a             
	andi.l #$F0, d7                         ; 00C00E: 0287000000f0         
	or.l d7, d1                             ; 00C014: 8287                 
	lsl.l #$4, d1                           ; 00C016: e989                 
	move.b $C(a0, d0.w), d7                 ; 00C018: 1e30000c             
	andi.l #$F0, d7                         ; 00C01C: 0287000000f0         
	or.l d7, d1                             ; 00C022: 8287                 
	move.b $E(a0, d0.w), d7                 ; 00C024: 1e30000e             
	andi.l #$F0, d7                         ; 00C028: 0287000000f0         
	lsr.l #$4, d7                           ; 00C02E: e88f                 
	or.l d7, d1                             ; 00C030: 8287                 
	move.l d1, $FFE472.l                    ; 00C032: 23c100ffe472         
	move.l d1, d0                           ; 00C038: 2001                 
	movea.l a0, a5                          ; 00C03A: 2a48                 
	adda.l #$520, a5                        ; 00C03C: dbfc00000520         
	movea.l d2, a2                          ; 00C042: 2442                 

HNU_NextByte:
	move.b (a5), d4                         ; 00C044: 1815                 
	andi.b #$F0, d4                         ; 00C046: 020400f0             
	move.b $2(a5), d5                       ; 00C04A: 1a2d0002             
	andi.b #$F0, d5                         ; 00C04E: 020500f0             
	lsr.b #$4, d5                           ; 00C052: e80d                 
	or.b d5, d4                             ; 00C054: 8805                 
	addq.l #$4, a5                          ; 00C056: 588d                 

loc_00C058:
	move.w (a2)+, d3                        ; 00C058: 361a                 
	bpl.b loc_00C0B6                        ; 00C05A: 6a5a                 
	lsr.b #$1, d4                           ; 00C05C: e20c                 
	bcc.b loc_00C062                        ; 00C05E: 6402                 
	suba.w d3, a2                           ; 00C060: 94c3                 

loc_00C062:
	move.w (a2)+, d3                        ; 00C062: 361a                 
	bpl.b loc_00C0C0                        ; 00C064: 6a5a                 
	lsr.b #$1, d4                           ; 00C066: e20c                 
	bcc.b loc_00C06C                        ; 00C068: 6402                 
	suba.w d3, a2                           ; 00C06A: 94c3                 

loc_00C06C:
	move.w (a2)+, d3                        ; 00C06C: 361a                 
	bpl.w loc_00C0CA                        ; 00C06E: 6a00005a             
	lsr.b #$1, d4                           ; 00C072: e20c                 
	bcc.b loc_00C078                        ; 00C074: 6402                 
	suba.w d3, a2                           ; 00C076: 94c3                 

loc_00C078:
	move.w (a2)+, d3                        ; 00C078: 361a                 
	bpl.w loc_00C0D4                        ; 00C07A: 6a000058             
	lsr.b #$1, d4                           ; 00C07E: e20c                 
	bcc.b loc_00C084                        ; 00C080: 6402                 
	suba.w d3, a2                           ; 00C082: 94c3                 

loc_00C084:
	move.w (a2)+, d3                        ; 00C084: 361a                 
	bpl.w loc_00C0DE                        ; 00C086: 6a000056             
	lsr.b #$1, d4                           ; 00C08A: e20c                 
	bcc.b loc_00C090                        ; 00C08C: 6402                 
	suba.w d3, a2                           ; 00C08E: 94c3                 

loc_00C090:
	move.w (a2)+, d3                        ; 00C090: 361a                 
	bpl.w loc_00C0E8                        ; 00C092: 6a000054             
	lsr.b #$1, d4                           ; 00C096: e20c                 
	bcc.b loc_00C09C                        ; 00C098: 6402                 
	suba.w d3, a2                           ; 00C09A: 94c3                 

loc_00C09C:
	move.w (a2)+, d3                        ; 00C09C: 361a                 
	bpl.w loc_00C0F2                        ; 00C09E: 6a000052             
	lsr.b #$1, d4                           ; 00C0A2: e20c                 
	bcc.b loc_00C0A8                        ; 00C0A4: 6402                 
	suba.w d3, a2                           ; 00C0A6: 94c3                 

loc_00C0A8:
	move.w (a2)+, d3                        ; 00C0A8: 361a                 
	bpl.w loc_00C0FC                        ; 00C0AA: 6a000050             
	lsr.b #$1, d4                           ; 00C0AE: e20c                 
	bcc.b HNU_NextByte                      ; 00C0B0: 6492                 
	suba.w d3, a2                           ; 00C0B2: 94c3                 
	bra.b HNU_NextByte                      ; 00C0B4: 608e                 

loc_00C0B6:
	move.b d3, (a1)+                        ; 00C0B6: 12c3                 
	movea.l d2, a2                          ; 00C0B8: 2442                 
	dbra d0, loc_00C058                     ; 00C0BA: 51c8ff9c             
	rts                                     ; 00C0BE: 4e75                 

loc_00C0C0:
	move.b d3, (a1)+                        ; 00C0C0: 12c3                 
	movea.l d2, a2                          ; 00C0C2: 2442                 
	dbra d0, loc_00C062                     ; 00C0C4: 51c8ff9c             
	rts                                     ; 00C0C8: 4e75                 

loc_00C0CA:
	move.b d3, (a1)+                        ; 00C0CA: 12c3                 
	movea.l d2, a2                          ; 00C0CC: 2442                 
	dbra d0, loc_00C06C                     ; 00C0CE: 51c8ff9c             
	rts                                     ; 00C0D2: 4e75                 

loc_00C0D4:
	move.b d3, (a1)+                        ; 00C0D4: 12c3                 
	movea.l d2, a2                          ; 00C0D6: 2442                 
	dbra d0, loc_00C078                     ; 00C0D8: 51c8ff9e             
	rts                                     ; 00C0DC: 4e75                 

loc_00C0DE:
	move.b d3, (a1)+                        ; 00C0DE: 12c3                 
	movea.l d2, a2                          ; 00C0E0: 2442                 
	dbra d0, loc_00C084                     ; 00C0E2: 51c8ffa0             
	rts                                     ; 00C0E6: 4e75                 

loc_00C0E8:
	move.b d3, (a1)+                        ; 00C0E8: 12c3                 
	movea.l d2, a2                          ; 00C0EA: 2442                 
	dbra d0, loc_00C090                     ; 00C0EC: 51c8ffa2             
	rts                                     ; 00C0F0: 4e75                 

loc_00C0F2:
	move.b d3, (a1)+                        ; 00C0F2: 12c3                 
	movea.l d2, a2                          ; 00C0F4: 2442                 
	dbra d0, loc_00C09C                     ; 00C0F6: 51c8ffa4             
	rts                                     ; 00C0FA: 4e75                 

loc_00C0FC:
	move.b d3, (a1)+                        ; 00C0FC: 12c3                 
	movea.l d2, a2                          ; 00C0FE: 2442                 
	dbra d0, loc_00C0A8                     ; 00C100: 51c8ffa6             
	rts                                     ; 00C104: 4e75                 
