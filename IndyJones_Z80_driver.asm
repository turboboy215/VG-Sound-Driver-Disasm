; Indiana Jones and the Last Crusade (JE) - Mega Drive
; Tiertex sound driver (Z80 side), by Donald Campbell
; Source: ROM $00F0E2-$00F6F7 ($616 bytes), copied to Z80 RAM $0000 by 68k LoadSoundDriver ($00F092)
; Default voice bank ROM $00FEF8 ($3E0 bytes) -> Z80 $0A00
; Disassembled with z80dasm, labels/comments added. See Tiertex_SoundEngine.md for the data format.

Mus_FM1          equ $0800
Mus_FM2          equ $0830
Mus_FM3          equ $0860
Mus_FM4          equ $0890
Mus_FM5          equ $08C0
Mus_FM6          equ $08F0
SFX_FM3          equ $0920
SFX_FM4          equ $0950
SFX_FM5          equ $0980
SFX_FM6          equ $09B0
DAC_SaveLen      equ $09E0
DAC_SaveHL       equ $09E2
DAC_HalfVol      equ $09E4
DAC_Finished     equ $09ED
Paused           equ $09EE
PausedPrev       equ $09EF
DAC_Active       equ $09F0
PauseReq         equ $09F1
DAC_TimerA       equ $09F6
DAC_Addr         equ $09F8
DAC_Len          equ $09FA
DAC_Bank         equ $09FC
DAC_LoopBank     equ $09FE
VoiceBank        equ $0A00
FreqTable        equ $1F00
StackTop         equ $2000
YM_A0            equ $4000
YM_D0            equ $4001
YM_A1            equ $4002
YM_D1            equ $4003
BankReg          equ $6000
Bank_LastByte    equ $FFFF

	org $0000

; Cold start. Alt regs: B'=$A4+ch (freq-hi reg), D'E'=$4000/$4002 (YM part), H'=$1F (freq table page)
Z80_Reset:
	di                      ; 0000: f3           
	im 1                    ; 0001: ed 56        
	ld sp,StackTop          ; 0003: 31 00 20     stack at top of Z80 RAM
	ld h,$1F                ; 0006: 26 1f        H' = freq table page
	ld b,$A4                ; 0008: 06 a4        B' = $A4 (FM1 freq hi reg)
	ld de,YM_A0             ; 000A: 11 00 40     DE' = YM part I
	ld a,$22                ; 000D: 3e 22        reg $22 = $09: LFO on, 5.56 Hz
	ld (de),a               ; 000F: 12           
	rst $30                 ; 0010: f7           
	ld a,$09                ; 0011: 3e 09        
	inc e                   ; 0013: 1c           
	ld (de),a               ; 0014: 12           
	dec e                   ; 0015: 1d           
	exx                     ; 0016: d9           
	ld hl,Mus_FM1           ; 0017: 21 00 08     clear $0800-$09FF (track RAM)
	ld de,$0801             ; 001A: 11 01 08     
	ld bc,$01FF             ; 001D: 01 ff 01     
	ld (hl),l               ; 0020: 75           
	ldir                    ; 0021: ed b0        
	jp InitFreqTable        ; 0023: c3 3a 00     
	nop                     ; 0026: 00           
	nop                     ; 0027: 00           

; RST $28: YM2612 write-recovery delay (falls into Delay_Short). A is preserved.
Delay_Long:
	sub (ix+$00)            ; 0028: dd 96 00     
	add a,(ix+$00)          ; 002B: dd 86 00     
	nop                     ; 002E: 00           
	nop                     ; 002F: 00           

; RST $30: short YM2612 write-recovery delay
Delay_Short:
	sub (ix+$00)            ; 0030: dd 96 00     
	add a,(ix+$00)          ; 0033: dd 86 00     
	ret                     ; 0036: c9           
	nop                     ; 0037: 00           

; VBlank IRQ unused (interrupts disabled)
IRQ_Handler:
	reti                    ; 0038: ed 4d        

; Copy 14 base F-nums to $1F00 then extend upward: each entry +12 = same F-num, block+1
InitFreqTable:
	ld hl,FreqTableInit     ; 003A: 21 fc 05     
	ld de,FreqTable         ; 003D: 11 00 1f     
	ld bc,$001C             ; 0040: 01 1c 00     
	ldir                    ; 0043: ed b0        
	ld hl,$1F02             ; 0045: 21 02 1f     
	ld e,$1A                ; 0048: 1e 1a        
	ld bc,$54FF             ; 004A: 01 ff 54     

InitFreqTable_Loop:
	ldi                     ; 004D: ed a0        
	ld a,(hl)               ; 004F: 7e           
	add a,$08               ; 0050: c6 08        
	ld (de),a               ; 0052: 12           
	inc hl                  ; 0053: 23           
	inc de                  ; 0054: 13           
	djnz InitFreqTable_Loop ; 0055: 10 f6        
	jp Z80_Main             ; 0057: c3 fe 04     
	nop                     ; 005A: 00           
	nop                     ; 005B: 00           
	nop                     ; 005C: 00           
	nop                     ; 005D: 00           
	nop                     ; 005E: 00           
	nop                     ; 005F: 00           
	nop                     ; 0060: 00           
	nop                     ; 0061: 00           
	nop                     ; 0062: 00           
	nop                     ; 0063: 00           
	nop                     ; 0064: 00           
	nop                     ; 0065: 00           

NMI_Handler:
	retn                    ; 0066: ed 45        
	halt                    ; 0068: 76           

; Called once per Timer B tick. Runs all 6 FM channels (FM3-6 arbitrate SFX over music).
UpdateAllChannels:
	push bc                 ; 0069: c5           
	exx                     ; 006A: d9           
	ld b,$A4                ; 006B: 06 a4        
	ld de,YM_A0             ; 006D: 11 00 40     
	exx                     ; 0070: d9           
	ld ix,Mus_FM1           ; 0071: dd 21 00 08  FM1 music
	call UpdateTrack        ; 0075: cd 2e 01     
	exx                     ; 0078: d9           
	inc b                   ; 0079: 04           
	exx                     ; 007A: d9           
	ld ix,Mus_FM2           ; 007B: dd 21 30 08  FM2 music
	call UpdateTrack        ; 007F: cd 2e 01     
	exx                     ; 0082: d9           
	inc b                   ; 0083: 04           
	exx                     ; 0084: d9           
	ld ix,SFX_FM3           ; 0085: dd 21 20 09  FM3 SFX
	ld de,Mus_FM3           ; 0089: 11 60 08     FM3 music
	call UpdateSharedChannel; 008C: cd f4 00     
	exx                     ; 008F: d9           
	ld e,$02                ; 0090: 1e 02        switch to YM part II
	ld b,$A4                ; 0092: 06 a4        
	exx                     ; 0094: d9           
	ld ix,SFX_FM4           ; 0095: dd 21 50 09  FM4 SFX
	ld de,Mus_FM4           ; 0099: 11 90 08     FM4 music
	call UpdateSharedChannel; 009C: cd f4 00     
	exx                     ; 009F: d9           
	inc b                   ; 00A0: 04           
	exx                     ; 00A1: d9           
	ld ix,SFX_FM5           ; 00A2: dd 21 80 09  FM5 SFX
	ld de,Mus_FM5           ; 00A6: 11 c0 08     FM5 music
	call UpdateSharedChannel; 00A9: cd f4 00     
	exx                     ; 00AC: d9           
	inc b                   ; 00AD: 04           
	ld a,(DAC_Active)       ; 00AE: 3a f0 09     DAC playing?
	and a                   ; 00B1: a7           
	jr z,UpdFM6             ; 00B2: 28 03        
	ld de,FreqTable         ; 00B4: 11 00 1f     yes: FM6 writes go to dummy port

UpdFM6:
	exx                     ; 00B7: d9           
	ld ix,SFX_FM6           ; 00B8: dd 21 b0 09  FM6 SFX
	ld de,Mus_FM6           ; 00BC: 11 f0 08     FM6 music
	ld a,(DAC_Finished)     ; 00BF: 3a ed 09     DAC just finished?
	and a                   ; 00C2: a7           
	jr z,UpdFM6_Run         ; 00C3: 28 24        
	call KeyOff             ; 00C5: cd e6 01     key off FM6, restore its voice
	xor a                   ; 00C8: af           
	ld (DAC_Finished),a     ; 00C9: 32 ed 09     
	ld a,(ix+$00)           ; 00CC: dd 7e 00     
	or (ix+$01)             ; 00CF: dd b6 01     
	jr z,UpdFM6_RestoreMusic; 00D2: 28 05        
	call ReloadVoice        ; 00D4: cd cb 01     
	jr UpdFM6_Run           ; 00D7: 18 10        

UpdFM6_RestoreMusic:
	push de                 ; 00D9: d5           
	ex de,hl                ; 00DA: eb           
	ld a,(hl)               ; 00DB: 7e           
	inc l                   ; 00DC: 2c           
	or (hl)                 ; 00DD: b6           
	jr z,UpdFM6_Done        ; 00DE: 28 08        
	ex de,hl                ; 00E0: eb           
	ex (sp),ix              ; 00E1: dd e3        
	call ReloadVoice        ; 00E3: cd cb 01     
	ex (sp),ix              ; 00E6: dd e3        

UpdFM6_Done:
	pop de                  ; 00E8: d1           

UpdFM6_Run:
	call UpdateSharedChannel; 00E9: cd f4 00     
	pop bc                  ; 00EC: c1           
	ld a,(Paused)           ; 00ED: 3a ee 09     remember pause state
	ld (PausedPrev),a       ; 00F0: 32 ef 09     
	ret                     ; 00F3: c9           

; IX = SFX track, DE = music track for the same FM channel.
; If SFX is active it plays; music keeps running with its register writes sent to a dummy port ($1F00).
UpdateSharedChannel:
	ld a,(ix+$07)           ; 00F4: dd 7e 07     SFX start requested?
	and a                   ; 00F7: a7           
	jr nz,USC_SfxActive     ; 00F8: 20 08        
	ld a,(ix+$00)           ; 00FA: dd 7e 00     SFX active?
	or (ix+$01)             ; 00FD: dd b6 01     
	jr z,USC_MusicOnly      ; 0100: 28 29        

USC_SfxActive:
	push de                 ; 0102: d5           
	call UpdateTrack        ; 0103: cd 2e 01     
	ld a,(ix+$00)           ; 0106: dd 7e 00     
	or (ix+$01)             ; 0109: dd b6 01     
	pop ix                  ; 010C: dd e1        
	jr z,USC_SfxJustEnded   ; 010E: 28 0d        
	exx                     ; 0110: d9           
	push de                 ; 0111: d5           
	ld de,FreqTable         ; 0112: 11 00 1f     mute the music track
	exx                     ; 0115: d9           
	call UpdateTrack        ; 0116: cd 2e 01     
	exx                     ; 0119: d9           
	pop de                  ; 011A: d1           
	exx                     ; 011B: d9           
	ret                     ; 011C: c9           

USC_SfxJustEnded:
	call KeyOff             ; 011D: cd e6 01     
	ld a,(ix+$00)           ; 0120: dd 7e 00     
	or (ix+$01)             ; 0123: dd b6 01     
	call nz,ReloadVoice     ; 0126: c4 cb 01     
	jr UpdateTrack          ; 0129: 18 03        

USC_MusicOnly:
	push de                 ; 012B: d5           
	pop ix                  ; 012C: dd e1        

; Process one track (IX) for one tick. Services a pending DAC sample first (Timer A poll).
UpdateTrack:
	ld hl,YM_A0             ; 012E: 21 00 40     read YM status
	ld (hl),$27             ; 0131: 36 27        
	ld a,(hl)               ; 0133: 7e           
	and $01                 ; 0134: e6 01        Timer A overflowed?
	jr z,UT_CheckPause      ; 0136: 28 1b        
	push bc                 ; 0138: c5           
	push de                 ; 0139: d5           
	push hl                 ; 013A: e5           
	push ix                 ; 013B: dd e5        
	ld bc,(DAC_SaveLen)     ; 013D: ed 4b e0 09  
	ld hl,(DAC_SaveHL)      ; 0141: 2a e2 09     
	call DAC_Output         ; 0144: cd 3c 05     yes: output a DAC sample now
	ld (DAC_SaveHL),hl      ; 0147: 22 e2 09     
	ld (DAC_SaveLen),bc     ; 014A: ed 43 e0 09  
	pop ix                  ; 014E: dd e1        
	pop hl                  ; 0150: e1           
	pop de                  ; 0151: d1           
	pop bc                  ; 0152: c1           

UT_CheckPause:
	ld a,(Paused)           ; 0153: 3a ee 09     paused?
	and a                   ; 0156: a7           
	jp nz,PauseChannel      ; 0157: c2 f7 01     
	ld a,(PausedPrev)       ; 015A: 3a ef 09     just un-paused?
	and a                   ; 015D: a7           
	call nz,ReloadVoice     ; 015E: c4 cb 01     
	ld a,(ix+$07)           ; 0161: dd 7e 07     start request (68k writes 1)
	and a                   ; 0164: a7           
	jr z,UT_Tick            ; 0165: 28 39        
	dec a                   ; 0167: 3d           
	jr nz,UT_Tick           ; 0168: 20 36        
	call KeyOff             ; 016A: cd e6 01     
	ld l,(ix+$05)           ; 016D: dd 6e 05     ptr = start ptr
	ld (ix+$00),l           ; 0170: dd 75 00     
	ld h,(ix+$06)           ; 0173: dd 66 06     
	ld (ix+$01),h           ; 0176: dd 74 01     
	push hl                 ; 0179: e5           
	ld l,(ix+$11)           ; 017A: dd 6e 11     
	ld h,(ix+$12)           ; 017D: dd 66 12     
	push hl                 ; 0180: e5           
	push ix                 ; 0181: dd e5        
	pop hl                  ; 0183: e1           
	inc hl                  ; 0184: 23           
	inc hl                  ; 0185: 23           
	ld e,l                  ; 0186: 5d           
	ld d,h                  ; 0187: 54           
	inc de                  ; 0188: 13           
	push bc                 ; 0189: c5           
	ld bc,$002D             ; 018A: 01 2d 00     clear IX+2..IX+$2F (keeps +5/6 start, +$11/12 freq base)
	ld (hl),$00             ; 018D: 36 00        
	ldir                    ; 018F: ed b0        
	pop bc                  ; 0191: c1           
	pop hl                  ; 0192: e1           
	ld (ix+$11),l           ; 0193: dd 75 11     
	ld (ix+$12),h           ; 0196: dd 74 12     
	pop hl                  ; 0199: e1           
	ld (ix+$05),l           ; 019A: dd 75 05     
	ld (ix+$06),h           ; 019D: dd 74 06     

UT_Tick:
	ld l,(ix+$00)           ; 01A0: dd 6e 00     
	ld h,(ix+$01)           ; 01A3: dd 66 01     
	ld a,h                  ; 01A6: 7c           
	or l                    ; 01A7: b5           
	ret z                   ; 01A8: c8           
	ld e,(ix+$02)           ; 01A9: dd 5e 02     delay counter
	ld d,(ix+$03)           ; 01AC: dd 56 03     
	ld a,e                  ; 01AF: 7b           
	or d                    ; 01B0: b2           
	jp z,Seq_ReadNext       ; 01B1: ca 1f 04     0 -> read next event
	ld a,d                  ; 01B4: 7a           
	and a                   ; 01B5: a7           
	jr nz,UT_StoreDelay     ; 01B6: 20 0b        
	ld a,e                  ; 01B8: 7b           
	dec a                   ; 01B9: 3d           
	jr nz,UT_StoreDelay     ; 01BA: 20 07        
	ld a,(ix+$21)           ; 01BC: dd 7e 21     1 tick left: key off unless legato
	and a                   ; 01BF: a7           
	call z,KeyOff           ; 01C0: cc e6 01     

UT_StoreDelay:
	dec de                  ; 01C3: 1b           
	ld (ix+$02),e           ; 01C4: dd 73 02     
	ld (ix+$03),d           ; 01C7: dd 72 03     
	ret                     ; 01CA: c9           

; Re-send the voice last loaded on this track (pointer at IX+$1F)
ReloadVoice:
	exx                     ; 01CB: d9           
	push bc                 ; 01CC: c5           
	push de                 ; 01CD: d5           
	push hl                 ; 01CE: e5           
	ld a,b                  ; 01CF: 78           
	and $03                 ; 01D0: e6 03        C = $30 + ch (first operator reg)
	or $30                  ; 01D2: f6 30        
	ld c,a                  ; 01D4: 4f           
	ld b,$1C                ; 01D5: 06 1c        
	ex de,hl                ; 01D7: eb           
	ld e,(ix+$1F)           ; 01D8: dd 5e 1f     
	ld d,(ix+$20)           ; 01DB: dd 56 20     
	call WriteVoice         ; 01DE: cd b1 02     
	pop hl                  ; 01E1: e1           
	pop de                  ; 01E2: d1           
	pop bc                  ; 01E3: c1           
	exx                     ; 01E4: d9           
	ret                     ; 01E5: c9           

; Key-off the current channel (reg $28)
KeyOff:
	exx                     ; 01E6: d9           
	ld c,e                  ; 01E7: 4b           
	ld a,$28                ; 01E8: 3e 28        reg $28
	ld e,$00                ; 01EA: 1e 00        
	ld (de),a               ; 01EC: 12           
	ld a,b                  ; 01ED: 78           
	and $03                 ; 01EE: e6 03        
	add a,c                 ; 01F0: 81           ch + 4 if part II (E'=2)
	add a,c                 ; 01F1: 81           
	inc e                   ; 01F2: 1c           
	ld (de),a               ; 01F3: 12           
	ld e,c                  ; 01F4: 59           
	exx                     ; 01F5: d9           
	ret                     ; 01F6: c9           

; Paused: load SilentVoice, key off, pan off
PauseChannel:
	exx                     ; 01F7: d9           
	push bc                 ; 01F8: c5           
	push hl                 ; 01F9: e5           
	ld a,b                  ; 01FA: 78           
	and $03                 ; 01FB: e6 03        
	or $30                  ; 01FD: f6 30        
	ld c,a                  ; 01FF: 4f           
	ld b,$1C                ; 0200: 06 1c        
	ex de,hl                ; 0202: eb           
	ld de,SilentVoice       ; 0203: 11 1d 02     
	call WriteVoice         ; 0206: cd b1 02     
	ex de,hl                ; 0209: eb           
	pop hl                  ; 020A: e1           
	pop bc                  ; 020B: c1           
	exx                     ; 020C: d9           
	call KeyOff             ; 020D: cd e6 01     then pan off:
	exx                     ; 0210: d9           
	ld a,b                  ; 0211: 78           
	and $03                 ; 0212: e6 03        
	or $B4                  ; 0214: f6 b4        
	ld (de),a               ; 0216: 12           
	inc e                   ; 0217: 1c           
	xor a                   ; 0218: af           
	ld (de),a               ; 0219: 12           
	dec e                   ; 021A: 1d           
	exx                     ; 021B: d9           
	ret                     ; 021C: c9           

; 30-byte voice with TL=$7F, fastest envelope (used for pause)
SilentVoice:
	defb $00                ; 021D: 00           
	defb $00                ; 021E: 00           
	defb $00                ; 021F: 00           
	defb $00                ; 0220: 00           
	defb $00                ; 0221: 00           
	defb $FF                ; 0222: ff           
	defb $FF                ; 0223: ff           
	defb $FF                ; 0224: ff           
	defb $FF                ; 0225: ff           
	defb $1F                ; 0226: 1f           
	defb $1F                ; 0227: 1f           
	defb $1F                ; 0228: 1f           
	defb $1F                ; 0229: 1f           
	defb $1F                ; 022A: 1f           
	defb $1F                ; 022B: 1f           
	defb $1F                ; 022C: 1f           
	defb $1F                ; 022D: 1f           
	defb $1F                ; 022E: 1f           
	defb $1F                ; 022F: 1f           
	defb $1F                ; 0230: 1f           
	defb $1F                ; 0231: 1f           
	defb $FE                ; 0232: fe           
	defb $FE                ; 0233: fe           
	defb $FE                ; 0234: fe           
	defb $FE                ; 0235: fe           
	defb $00                ; 0236: 00           
	defb $00                ; 0237: 00           
	defb $00                ; 0238: 00           
	defb $00                ; 0239: 00           
	defb $00                ; 023A: 00           
	defb $00                ; 023B: 00           
	defb $00                ; 023C: 00           

; A = sequence byte >= $80
Seq_Command:
	ld b,a                  ; 023D: 47           
	cp $A0                  ; 023E: fe a0        $A0 inline voice
	jr z,Cmd_A0_InlineVoice ; 0240: 28 33        
	and $E0                 ; 0242: e6 e0        $80-$9F?
	cp $80                  ; 0244: fe 80        
	jp nz,Seq_CmdEx         ; 0246: c2 ee 02     
	ld a,b                  ; 0249: 78           
	and $1F                 ; 024A: e6 1f        
	cp $1F                  ; 024C: fe 1f        $9F keysplit
	jr nz,Cmd_Voice         ; 024E: 20 34        
	inc hl                  ; 0250: 23           +8 = split note
	ld a,(hl)               ; 0251: 7e           
	ld (ix+$08),a           ; 0252: dd 77 08     
	ld (ix+$09),$01         ; 0255: dd 36 09 01  +9 = current side (1)
	inc hl                  ; 0259: 23           +A = lo voice
	ld a,(hl)               ; 025A: 7e           
	ld (ix+$0A),a           ; 025B: dd 77 0a     
	inc hl                  ; 025E: 23           +B = lo transpose
	ld a,(hl)               ; 025F: 7e           
	ld (ix+$0B),a           ; 0260: dd 77 0b     
	ld (ix+$04),a           ; 0263: dd 77 04     +4 = active transpose
	inc hl                  ; 0266: 23           
	ld a,(hl)               ; 0267: 7e           +C = hi voice
	ld (ix+$0C),a           ; 0268: dd 77 0c     
	inc hl                  ; 026B: 23           
	ld a,(hl)               ; 026C: 7e           +D = hi transpose
	ld (ix+$0D),a           ; 026D: dd 77 0d     
	ld a,(ix+$0A)           ; 0270: dd 7e 0a     
	jr LoadVoiceNum         ; 0273: 18 13        

Cmd_A0_InlineVoice:
	ld (ix+$08),$00         ; 0275: dd 36 08 00  
	inc hl                  ; 0279: 23           
	push hl                 ; 027A: e5           
	ld de,$001F             ; 027B: 11 1f 00     skip 32 bytes
	add hl,de               ; 027E: 19           
	exx                     ; 027F: d9           
	ld c,h                  ; 0280: 4c           
	pop hl                  ; 0281: e1           
	jr LoadVoicePtr         ; 0282: 18 12        

Cmd_Voice:
	ld (ix+$08),$00         ; 0284: dd 36 08 00  cancel keysplit

; A = voice number -> $0A00 + A*32
LoadVoiceNum:
	exx                     ; 0288: d9           
	ld c,h                  ; 0289: 4c           
	ld l,a                  ; 028A: 6f           HL' = $0A00 + n*32
	ld h,$00                ; 028B: 26 00        
	add hl,hl               ; 028D: 29           
	add hl,hl               ; 028E: 29           
	add hl,hl               ; 028F: 29           
	add hl,hl               ; 0290: 29           
	add hl,hl               ; 0291: 29           
	ld a,$0A                ; 0292: 3e 0a        
	add a,h                 ; 0294: 84           
	ld h,a                  ; 0295: 67           

LoadVoicePtr:
	push bc                 ; 0296: c5           
	ld a,b                  ; 0297: 78           
	and $03                 ; 0298: e6 03        
	or $30                  ; 029A: f6 30        
	ld c,a                  ; 029C: 4f           
	ld b,$1C                ; 029D: 06 1c        
	ex de,hl                ; 029F: eb           
	call WriteVoiceSave     ; 02A0: cd ab 02     
	ex de,hl                ; 02A3: eb           
	pop bc                  ; 02A4: c1           
	ld h,c                  ; 02A5: 61           
	exx                     ; 02A6: d9           
	inc hl                  ; 02A7: 23           
	jp Seq_ReadNext         ; 02A8: c3 1f 04     

; Remember voice pointer in IX+$1F/$20, then write it
WriteVoiceSave:
	ld (ix+$1F),e           ; 02AB: dd 73 1f     
	ld (ix+$20),d           ; 02AE: dd 72 20     

; DE = 30-byte voice: [B0 FB/ALG] [28 bytes regs $30-$9C, 4 slots each] [B4 pan/AMS/FMS, 0=>$C0]
WriteVoice:
	ld a,$28                ; 02B1: 3e 28        key off first
	ld (YM_A0),a            ; 02B3: 32 00 40     
	ld a,c                  ; 02B6: 79           
	and $03                 ; 02B7: e6 03        
	add a,l                 ; 02B9: 85           
	add a,l                 ; 02BA: 85           
	ld (YM_D0),a            ; 02BB: 32 01 40     
	ld a,c                  ; 02BE: 79           
	and $03                 ; 02BF: e6 03        
	or $B0                  ; 02C1: f6 b0        reg $B0+ch (FB/ALG)
	ld (hl),a               ; 02C3: 77           
	rst $30                 ; 02C4: f7           
	ld a,(de)               ; 02C5: 1a           
	inc de                  ; 02C6: 13           
	inc hl                  ; 02C7: 23           
	ld (hl),a               ; 02C8: 77           
	dec hl                  ; 02C9: 2b           
	rst $28                 ; 02CA: ef           

WriteVoice_Loop:
	ld (hl),c               ; 02CB: 71           
	rst $30                 ; 02CC: f7           
	ld a,c                  ; 02CD: 79           
	add a,$04               ; 02CE: c6 04        
	ld c,a                  ; 02D0: 4f           
	ld a,(de)               ; 02D1: 1a           
	inc de                  ; 02D2: 13           
	inc hl                  ; 02D3: 23           
	ld (hl),a               ; 02D4: 77           
	dec hl                  ; 02D5: 2b           
	rst $28                 ; 02D6: ef           
	djnz WriteVoice_Loop    ; 02D7: 10 f2        28 operator registers
	ld a,c                  ; 02D9: 79           
	and $03                 ; 02DA: e6 03        
	or $B4                  ; 02DC: f6 b4        reg $B4+ch
	ld (hl),a               ; 02DE: 77           
	rst $30                 ; 02DF: f7           
	inc hl                  ; 02E0: 23           
	ld a,(de)               ; 02E1: 1a           
	and a                   ; 02E2: a7           
	jr nz,WriteVoice_Pan    ; 02E3: 20 02        
	ld a,$C0                ; 02E5: 3e c0        0 => L+R

WriteVoice_Pan:
	ld (hl),a               ; 02E7: 77           
	ld (ix+$1E),a           ; 02E8: dd 77 1e     IX+$1E = pan
	dec hl                  ; 02EB: 2b           
	rst $28                 ; 02EC: ef           
	ret                     ; 02ED: c9           

; $A1-$EE: 1-byte no-op, $EF: freq base, $F0-$FF: jump table
Seq_CmdEx:
	ld a,b                  ; 02EE: 78           
	cp $EF                  ; 02EF: fe ef        $EF?
	jp z,Cmd_EF_FreqBase    ; 02F1: ca cf 03     
	jp c,Cmd_Nop            ; 02F4: da d9 03     $A1-$EE: skip
	push de                 ; 02F7: d5           
	sub $F0                 ; 02F8: d6 f0        
	add a,a                 ; 02FA: 87           
	ld de,CmdJumpTable      ; 02FB: 11 0d 03     
	add a,e                 ; 02FE: 83           
	ld e,a                  ; 02FF: 5f           
	adc a,d                 ; 0300: 8a           
	sub e                   ; 0301: 93           
	ld d,a                  ; 0302: 57           
	ld a,(de)               ; 0303: 1a           
	ld b,a                  ; 0304: 47           
	inc de                  ; 0305: 13           
	ld a,(de)               ; 0306: 1a           
	ld e,b                  ; 0307: 58           
	ld d,a                  ; 0308: 57           
	ex de,hl                ; 0309: eb           
	ex (sp),hl              ; 030A: e3           
	ex de,hl                ; 030B: eb           
	ret                     ; 030C: c9           

; $F0..$FF
CmdJumpTable:
	defw Cmd_Nop            ; 030D: d9 03        
	defw Cmd_Nop            ; 030F: d9 03        
	defw Cmd_Nop            ; 0311: d9 03        
	defw Cmd_Nop            ; 0313: d9 03        
	defw Cmd_F4_Cue68k      ; 0315: 2d 03        
	defw Cmd_F5_Legato      ; 0317: 4f 03        
	defw Cmd_F6_FixedDur    ; 0319: 64 03        
	defw Cmd_F7_DurFrac     ; 031B: dc 03        
	defw Cmd_F8_Return      ; 031D: 6d 03        
	defw Cmd_F9_Call        ; 031F: 84 03        
	defw Cmd_FA_DurFracClear; 0321: e2 03        
	defw Cmd_FB_DurFracLoop ; 0323: 00 04        
	defw Cmd_FC_LoopStart   ; 0325: 03 04        
	defw Cmd_FD_LoopEnd     ; 0327: 11 04        
	defw Cmd_FE_Stop        ; 0329: a7 03        
	defw Cmd_FF_Restart     ; 032B: 5b 03        

; Bank = $1FF (68k $FF8000) and write 1 to $FFFF => sets 68k byte $FFFFFF = 1
Cmd_F4_Cue68k:
	push hl                 ; 032D: e5           
	push de                 ; 032E: d5           
	push bc                 ; 032F: c5           
	ld hl,$01FF             ; 0330: 21 ff 01     bank = $1FF, 9 bits LSB first
	ld de,BankReg           ; 0333: 11 00 60     
	ld b,$09                ; 0336: 06 09        
	ld c,$01                ; 0338: 0e 01        

Cue68k_BankLoop:
	ld a,l                  ; 033A: 7d           
	and c                   ; 033B: a1           
	ld (de),a               ; 033C: 12           
	srl h                   ; 033D: cb 3c        
	rr l                    ; 033F: cb 1d        
	djnz Cue68k_BankLoop    ; 0341: 10 f7        
	pop bc                  ; 0343: c1           
	pop de                  ; 0344: d1           
	pop hl                  ; 0345: e1           
	inc hl                  ; 0346: 23           
	ld a,$01                ; 0347: 3e 01        
	ld (Bank_LastByte),a    ; 0349: 32 ff ff     68k $FFFFFF = 1
	jp Seq_ReadNext         ; 034C: c3 1f 04     

; Toggle IX+$21 (no key-off before next note)
Cmd_F5_Legato:
	ld a,(ix+$21)           ; 034F: dd 7e 21     
	xor $FF                 ; 0352: ee ff        
	ld (ix+$21),a           ; 0354: dd 77 21     
	inc hl                  ; 0357: 23           
	jp Seq_ReadNext         ; 0358: c3 1f 04     

; Jump to track start (IX+5/6)
Cmd_FF_Restart:
	ld l,(ix+$05)           ; 035B: dd 6e 05     
	ld h,(ix+$06)           ; 035E: dd 66 06     
	jp Seq_ReadNext         ; 0361: c3 1f 04     

; IX+$1D = n; while non-zero notes carry no duration byte
Cmd_F6_FixedDur:
	inc hl                  ; 0364: 23           
	ld a,(hl)               ; 0365: 7e           
	ld (ix+$1D),a           ; 0366: dd 77 1d     IX+$1D fixed duration
	inc hl                  ; 0369: 23           
	jp Seq_ReadNext         ; 036A: c3 1f 04     

; End of called block: repeat or return
Cmd_F8_Return:
	dec (ix+$1B)            ; 036D: dd 35 1b     IX+$1B call count
	jr z,Cmd_F8_Done        ; 0370: 28 09        
	ld l,(ix+$19)           ; 0372: dd 6e 19     jump back to called block
	ld h,(ix+$1A)           ; 0375: dd 66 1a     
	jp Seq_ReadNext         ; 0378: c3 1f 04     

Cmd_F8_Done:
	ld l,(ix+$17)           ; 037B: dd 6e 17     return after F9
	ld h,(ix+$18)           ; 037E: dd 66 18     
	jp Seq_ReadNext         ; 0381: c3 1f 04     

; F9 count transpose offs16(LE, relative to offset field)
Cmd_F9_Call:
	inc hl                  ; 0384: 23           
	ld a,(hl)               ; 0385: 7e           
	ld (ix+$1B),a           ; 0386: dd 77 1b     IX+$1B = count
	inc hl                  ; 0389: 23           
	ld a,(hl)               ; 038A: 7e           
	ld (ix+$1C),a           ; 038B: dd 77 1c     IX+$1C = transpose
	inc hl                  ; 038E: 23           
	push de                 ; 038F: d5           
	push hl                 ; 0390: e5           
	ld e,(hl)               ; 0391: 5e           
	inc hl                  ; 0392: 23           
	ld d,(hl)               ; 0393: 56           
	inc hl                  ; 0394: 23           
	ld (ix+$17),l           ; 0395: dd 75 17     IX+$17/18 = return address
	ld (ix+$18),h           ; 0398: dd 74 18     
	pop hl                  ; 039B: e1           
	add hl,de               ; 039C: 19           target = &offset + offset
	ld (ix+$19),l           ; 039D: dd 75 19     IX+$19/1A = target
	ld (ix+$1A),h           ; 03A0: dd 74 1a     
	pop de                  ; 03A3: d1           
	jp Seq_ReadNext         ; 03A4: c3 1f 04     

; Stop track, pan off, key off
Cmd_FE_Stop:
	ld (ix+$00),$00         ; 03A7: dd 36 00 00  track pointer = 0
	ld (ix+$01),$00         ; 03AB: dd 36 01 00  
	exx                     ; 03AF: d9           
	ld a,b                  ; 03B0: 78           
	and $03                 ; 03B1: e6 03        
	or $B4                  ; 03B3: f6 b4        reg $B4+ch = 0
	ld (de),a               ; 03B5: 12           
	rst $30                 ; 03B6: f7           
	inc e                   ; 03B7: 1c           
	xor a                   ; 03B8: af           
	ld (de),a               ; 03B9: 12           
	ld (ix+$1E),a           ; 03BA: dd 77 1e     
	dec e                   ; 03BD: 1d           
	rst $28                 ; 03BE: ef           
	ld a,$28                ; 03BF: 3e 28        key off
	ld c,e                  ; 03C1: 4b           
	ld e,$00                ; 03C2: 1e 00        
	ld (de),a               ; 03C4: 12           
	inc e                   ; 03C5: 1c           
	rst $30                 ; 03C6: f7           
	ld a,b                  ; 03C7: 78           
	and $03                 ; 03C8: e6 03        
	ld (de),a               ; 03CA: 12           
	ld e,c                  ; 03CB: 59           
	rst $28                 ; 03CC: ef           
	exx                     ; 03CD: d9           
	ret                     ; 03CE: c9           

; EF lo hi: note becomes raw F-num/block offset added to this base
Cmd_EF_FreqBase:
	inc hl                  ; 03CF: 23           
	ld a,(hl)               ; 03D0: 7e           
	ld (ix+$11),a           ; 03D1: dd 77 11     IX+$11/12 = freq base (0 = use table)
	inc hl                  ; 03D4: 23           
	ld a,(hl)               ; 03D5: 7e           
	ld (ix+$12),a           ; 03D6: dd 77 12     

Cmd_Nop:
	inc hl                  ; 03D9: 23           
	jr Seq_ReadNext         ; 03DA: 18 43        

; F7 lo hi: fractional duration add per note (16.16 accumulator)
Cmd_F7_DurFrac:
	call ReadDurFrac        ; 03DC: cd f5 03     
	inc hl                  ; 03DF: 23           
	jr Seq_ReadNext         ; 03E0: 18 3d        

Cmd_FA_DurFracClear:
	inc hl                  ; 03E2: 23           
	ld (ix+$15),$00         ; 03E3: dd 36 15 00  clear duration fraction
	ld (ix+$16),$00         ; 03E7: dd 36 16 00  
	ld (ix+$13),$00         ; 03EB: dd 36 13 00  
	ld (ix+$14),$00         ; 03EF: dd 36 14 00  
	jr Seq_ReadNext         ; 03F3: 18 2a        

ReadDurFrac:
	inc hl                  ; 03F5: 23           
	ld a,(hl)               ; 03F6: 7e           
	ld (ix+$15),a           ; 03F7: dd 77 15     
	inc hl                  ; 03FA: 23           
	ld a,(hl)               ; 03FB: 7e           
	ld (ix+$16),a           ; 03FC: dd 77 16     
	ret                     ; 03FF: c9           

; FB lo hi n = F7 lo hi + FC n
Cmd_FB_DurFracLoop:
	call ReadDurFrac        ; 0400: cd f5 03     

; FC n
Cmd_FC_LoopStart:
	inc hl                  ; 0403: 23           
	ld a,(hl)               ; 0404: 7e           
	inc hl                  ; 0405: 23           
	ld (ix+$0E),a           ; 0406: dd 77 0e     IX+$0E loop count
	ld (ix+$0F),l           ; 0409: dd 75 0f     IX+$0F/10 loop address
	ld (ix+$10),h           ; 040C: dd 74 10     
	jr Seq_ReadNext         ; 040F: 18 0e        

Cmd_FD_LoopEnd:
	inc hl                  ; 0411: 23           
	dec (ix+$0E)            ; 0412: dd 35 0e     loop count
	jr z,Seq_ReadNext       ; 0415: 28 08        
	ld l,(ix+$0F)           ; 0417: dd 6e 0f     
	ld h,(ix+$10)           ; 041A: dd 66 10     
	jr Seq_ReadNext         ; 041D: 18 00        

; Parse sequence bytes until a note/rest (which sets a new delay)
Seq_ReadNext:
	ld a,(hl)               ; 041F: 7e           
	bit 7,a                 ; 0420: cb 7f        command?
	jp nz,Seq_Command       ; 0422: c2 3d 02     
	ld c,a                  ; 0425: 4f           
	ld a,(ix+$08)           ; 0426: dd 7e 08     keysplit active?
	and a                   ; 0429: a7           
	jr z,Note_Play          ; 042A: 28 3c        
	ld b,a                  ; 042C: 47           
	ld a,c                  ; 042D: 79           
	sub b                   ; 042E: 90           A = (note >= split)
	ld a,$01                ; 042F: 3e 01        
	sbc a,$00               ; 0431: de 00        
	cp (ix+$09)             ; 0433: dd be 09     same side as before?
	jr z,Note_Play          ; 0436: 28 30        
	ld (ix+$09),a           ; 0438: dd 77 09     
	and a                   ; 043B: a7           
	jr nz,KeySplit_Hi       ; 043C: 20 0b        
	ld a,(ix+$0B)           ; 043E: dd 7e 0b     
	ld (ix+$04),a           ; 0441: dd 77 04     
	ld a,(ix+$0A)           ; 0444: dd 7e 0a     
	jr KeySplit_Reload      ; 0447: 18 09        

KeySplit_Hi:
	ld a,(ix+$0D)           ; 0449: dd 7e 0d     
	ld (ix+$04),a           ; 044C: dd 77 04     
	ld a,(ix+$0C)           ; 044F: dd 7e 0c     

KeySplit_Reload:
	dec hl                  ; 0452: 2b           
	jp LoadVoiceNum         ; 0453: c3 88 02     

Note_Rest:
	exx                     ; 0456: d9           
	ld c,e                  ; 0457: 4b           
	ld e,$00                ; 0458: 1e 00        
	ld a,$28                ; 045A: 3e 28        
	ld (de),a               ; 045C: 12           
	inc e                   ; 045D: 1c           
	ld a,b                  ; 045E: 78           
	and $03                 ; 045F: e6 03        
	add a,c                 ; 0461: 81           
	add a,c                 ; 0462: 81           
	ld (de),a               ; 0463: 12           
	ld e,c                  ; 0464: 59           
	jp Note_Duration        ; 0465: c3 c1 04     

Note_Play:
	ld a,(ix+$11)           ; 0468: dd 7e 11     raw F-num mode?
	or (ix+$12)             ; 046B: dd b6 12     
	jr z,Note_TableFreq     ; 046E: 28 22        
	call GetNote            ; 0470: cd 80 04     
	jr z,Note_Rest          ; 0473: 28 e1        
	exx                     ; 0475: d9           
	add a,(ix+$11)          ; 0476: dd 86 11     F-num = note + base
	ld c,a                  ; 0479: 4f           
	adc a,(ix+$12)          ; 047A: dd 8e 12     
	sub c                   ; 047D: 91           
	jr Note_WriteFreqKeyOn  ; 047E: 18 1d        

; A = note + call-transpose (if in F9 call) + voice transpose; Z set if rest
GetNote:
	ld a,c                  ; 0480: 79           
	and a                   ; 0481: a7           
	jr z,GetNote_Ret        ; 0482: 28 0d        
	ld a,(ix+$1B)           ; 0484: dd 7e 1b     
	and a                   ; 0487: a7           
	jr z,GetNote_Add        ; 0488: 28 03        
	ld a,(ix+$1C)           ; 048A: dd 7e 1c     

GetNote_Add:
	add a,c                 ; 048D: 81           
	add a,(ix+$04)          ; 048E: dd 86 04     

GetNote_Ret:
	ret                     ; 0491: c9           

Note_TableFreq:
	call GetNote            ; 0492: cd 80 04     
	jr z,Note_Rest          ; 0495: 28 bf        
	add a,a                 ; 0497: 87           index into FreqTable
	exx                     ; 0498: d9           
	ld l,a                  ; 0499: 6f           
	ld c,(hl)               ; 049A: 4e           
	inc l                   ; 049B: 2c           
	ld a,(hl)               ; 049C: 7e           

Note_WriteFreqKeyOn:
	ld l,a                  ; 049D: 6f           
	ld a,b                  ; 049E: 78           reg $A4+ch (block/F-num hi)
	ld (de),a               ; 049F: 12           
	inc de                  ; 04A0: 13           
	rst $30                 ; 04A1: f7           
	ld a,l                  ; 04A2: 7d           
	ld (de),a               ; 04A3: 12           
	rst $28                 ; 04A4: ef           
	dec de                  ; 04A5: 1b           
	ld a,b                  ; 04A6: 78           
	and $A3                 ; 04A7: e6 a3        reg $A0+ch
	ld (de),a               ; 04A9: 12           
	inc de                  ; 04AA: 13           
	rst $30                 ; 04AB: f7           
	ld a,c                  ; 04AC: 79           
	ld (de),a               ; 04AD: 12           
	dec de                  ; 04AE: 1b           
	rst $28                 ; 04AF: ef           
	ld c,e                  ; 04B0: 4b           
	ld e,$00                ; 04B1: 1e 00        
	ld a,$28                ; 04B3: 3e 28        key on: reg $28 = $F0|ch
	ld (de),a               ; 04B5: 12           
	rst $30                 ; 04B6: f7           
	ld a,b                  ; 04B7: 78           
	and $03                 ; 04B8: e6 03        
	add a,c                 ; 04BA: 81           
	add a,c                 ; 04BB: 81           
	inc e                   ; 04BC: 1c           
	or $F0                  ; 04BD: f6 f0        
	ld (de),a               ; 04BF: 12           
	ld e,c                  ; 04C0: 59           

Note_Duration:
	exx                     ; 04C1: d9           
	inc hl                  ; 04C2: 23           
	ld a,(ix+$1D)           ; 04C3: dd 7e 1d     fixed duration?
	and a                   ; 04C6: a7           
	jr z,Note_ReadDur       ; 04C7: 28 03        
	ld e,a                  ; 04C9: 5f           
	jr Note_StoreDur        ; 04CA: 18 12        

Note_ReadDur:
	ld a,(hl)               ; 04CC: 7e           duration byte
	inc hl                  ; 04CD: 23           
	ld e,a                  ; 04CE: 5f           

Note_DurExt:
	ld a,(hl)               ; 04CF: 7e           
	cp $7F                  ; 04D0: fe 7f        $7F xx: add xx to duration
	jr nz,Note_StoreDur     ; 04D2: 20 0a        
	inc hl                  ; 04D4: 23           
	ld a,(hl)               ; 04D5: 7e           
	add a,e                 ; 04D6: 83           
	ld e,a                  ; 04D7: 5f           
	adc a,d                 ; 04D8: 8a           
	sub e                   ; 04D9: 93           
	ld d,a                  ; 04DA: 57           
	inc hl                  ; 04DB: 23           
	jr Note_DurExt          ; 04DC: 18 f1        

Note_StoreDur:
	ld (ix+$00),l           ; 04DE: dd 75 00     
	ld (ix+$01),h           ; 04E1: dd 74 01     
	ld l,(ix+$13)           ; 04E4: dd 6e 13     fraction accumulator +$13/14 += +$15/16
	ld h,(ix+$14)           ; 04E7: dd 66 14     
	ld c,(ix+$15)           ; 04EA: dd 4e 15     
	ld b,(ix+$16)           ; 04ED: dd 46 16     
	add hl,bc               ; 04F0: 09           
	ld (ix+$13),l           ; 04F1: dd 75 13     
	ld (ix+$14),h           ; 04F4: dd 74 14     
	jp nc,UT_StoreDelay     ; 04F7: d2 c3 01     
	inc de                  ; 04FA: 13           carry: one extra tick
	jp UT_StoreDelay        ; 04FB: c3 c3 01     

; Timer B = $DD (tick), Timer A from DAC_TimerA; poll timers forever
Z80_Main:
	ld ix,YM_A0             ; 04FE: dd 21 00 40  
	ld (ix+$00),$26         ; 0502: dd 36 00 26  reg $26 Timer B = $DD
	rst $30                 ; 0506: f7           
	ld (ix+$01),$DD         ; 0507: dd 36 01 dd  
	rst $28                 ; 050B: ef           
	ld hl,$FE00             ; 050C: 21 00 fe     default Timer A ($3F8)
	call SetTimerA          ; 050F: cd e9 05     
	ld (ix+$00),$27         ; 0512: dd 36 00 27  reg $27 = $3F: load+enable A,B, reset flags
	rst $30                 ; 0516: f7           
	ld (ix+$01),$3F         ; 0517: dd 36 01 3f  
	rst $28                 ; 051B: ef           
	ld hl,YM_A0             ; 051C: 21 00 40     
	ld bc,$0000             ; 051F: 01 00 00     
	ld (hl),$27             ; 0522: 36 27        
	call TimerB_Tick        ; 0524: cd a2 05     

MainLoop:
	ld (hl),$27             ; 0527: 36 27        

ML_WaitBusy:
	ld a,(hl)               ; 0529: 7e           
	bit 7,a                 ; 052A: cb 7f        wait not busy
	jr nz,ML_WaitBusy       ; 052C: 20 fb        

ML_WaitTimer:
	ld a,(hl)               ; 052E: 7e           
	and $03                 ; 052F: e6 03        wait for a timer flag
	jr z,ML_WaitTimer       ; 0531: 28 fb        
	and $02                 ; 0533: e6 02        Timer B has priority
	jr nz,TimerB_Tick       ; 0535: 20 6b        
	call DAC_Output         ; 0537: cd 3c 05     
	jr MainLoop             ; 053A: 18 eb        

; Timer A overflow: output one sample (BC = remaining, IY = pointer)
DAC_Output:
	inc l                   ; 053C: 2c           
	ld (hl),$1F             ; 053D: 36 1f        reg $27 = $1F: reset Timer A flag
	dec l                   ; 053F: 2d           
	ld a,(Paused)           ; 0540: 3a ee 09     paused: no DAC
	and a                   ; 0543: a7           
	ret nz                  ; 0544: c0           
	ld a,(DAC_Active)       ; 0545: 3a f0 09     already playing?
	and a                   ; 0548: a7           
	jr nz,DAC_WriteSample   ; 0549: 20 15        
	ld a,b                  ; 054B: 78           nothing queued
	or c                    ; 054C: b1           
	ret z                   ; 054D: c8           
	ld a,$01                ; 054E: 3e 01        
	ld (DAC_Active),a       ; 0550: 32 f0 09     
	ld (hl),$2B             ; 0553: 36 2b        reg $2B = $80 DAC on; $B6 = $C0 FM6 pan L+R
	inc l                   ; 0555: 2c           
	ld (hl),$80             ; 0556: 36 80        
	inc l                   ; 0558: 2c           
	ld (hl),$B6             ; 0559: 36 b6        
	inc l                   ; 055B: 2c           
	ld (hl),$C0             ; 055C: 36 c0        
	ld l,$00                ; 055E: 2e 00        

DAC_WriteSample:
	ld (hl),$2A             ; 0560: 36 2a        reg $2A DAC data
	ld a,(DAC_HalfVol)      ; 0562: 3a e4 09     music playing -> half volume
	and a                   ; 0565: a7           
	jr z,DAC_FullVol        ; 0566: 28 11        
	ld a,(iy+$00)           ; 0568: fd 7e 00     
	inc l                   ; 056B: 2c           
	push bc                 ; 056C: c5           
	srl a                   ; 056D: cb 3f        sample >> 1 (SUB result unused)
	ld b,a                  ; 056F: 47           
	srl a                   ; 0570: cb 3f        
	srl a                   ; 0572: cb 3f        
	sub b                   ; 0574: 90           
	ld a,b                  ; 0575: 78           
	pop bc                  ; 0576: c1           
	jr DAC_Store            ; 0577: 18 04        

DAC_FullVol:
	ld a,(iy+$00)           ; 0579: fd 7e 00     
	inc l                   ; 057C: 2c           

DAC_Store:
	ld (hl),a               ; 057D: 77           
	inc iy                  ; 057E: fd 23        
	dec l                   ; 0580: 2d           
	dec bc                  ; 0581: 0b           
	ld a,b                  ; 0582: 78           
	or c                    ; 0583: b1           
	ret nz                  ; 0584: c0           
	ld (hl),$2B             ; 0585: 36 2b        end of sample: reg $2B
	inc l                   ; 0587: 2c           
	push hl                 ; 0588: e5           
	ld hl,(DAC_LoopBank)    ; 0589: 2a fe 09     loop bank set?
	ld a,h                  ; 058C: 7c           
	or l                    ; 058D: b5           
	jr z,DAC_Stop           ; 058E: 28 06        
	call DAC_StartSample    ; 0590: cd c7 05     
	pop hl                  ; 0593: e1           
	dec l                   ; 0594: 2d           
	ret                     ; 0595: c9           

DAC_Stop:
	pop hl                  ; 0596: e1           
	ld (DAC_Active),a       ; 0597: 32 f0 09     DAC_Active = 0; $2B = 0 DAC off
	ld (hl),a               ; 059A: 77           
	ld a,$01                ; 059B: 3e 01        tell channel update to restore FM6
	ld (DAC_Finished),a     ; 059D: 32 ed 09     
	dec l                   ; 05A0: 2d           
	ret                     ; 05A1: c9           

; Music/SFX tick, then start a newly requested sample
TimerB_Tick:
	ld (DAC_SaveHL),hl      ; 05A2: 22 e2 09     
	ld (DAC_SaveLen),bc     ; 05A5: ed 43 e0 09  
	inc l                   ; 05A9: 2c           
	ld (hl),$2F             ; 05AA: 36 2f        reg $27 = $2F: reset Timer B flag
	ld a,(PauseReq)         ; 05AC: 3a f1 09     latch pause request
	ld (Paused),a           ; 05AF: 32 ee 09     
	call UpdateAllChannels  ; 05B2: cd 69 00     
	ld bc,(DAC_SaveLen)     ; 05B5: ed 4b e0 09  
	ld hl,(DAC_Bank)        ; 05B9: 2a fc 09     new sample requested?
	ld a,h                  ; 05BC: 7c           
	or l                    ; 05BD: b5           
	call nz,DAC_StartSample ; 05BE: c4 c7 05     
	ld hl,(DAC_SaveHL)      ; 05C1: 2a e2 09     
	jp MainLoop             ; 05C4: c3 27 05     

; HL = 9-bit bank. Set bank, clear trigger, load IY/BC, program Timer A
DAC_StartSample:
	ld ix,YM_A0             ; 05C7: dd 21 00 40  
	ld de,BankReg           ; 05CB: 11 00 60     Z80 bank register
	ld b,$09                ; 05CE: 06 09        
	ld c,$01                ; 05D0: 0e 01        

DSS_BankLoop:
	ld a,l                  ; 05D2: 7d           
	and c                   ; 05D3: a1           
	ld (de),a               ; 05D4: 12           
	srl h                   ; 05D5: cb 3c        
	rr l                    ; 05D7: cb 1d        
	djnz DSS_BankLoop       ; 05D9: 10 f7        
	ld (DAC_Bank),hl        ; 05DB: 22 fc 09     store remaining bits (0) -> clears trigger
	ld iy,(DAC_Addr)        ; 05DE: fd 2a f8 09  
	ld bc,(DAC_Len)         ; 05E2: ed 4b fa 09  
	ld hl,(DAC_TimerA)      ; 05E6: 2a f6 09     

; H -> reg $24, L -> reg $25
SetTimerA:
	ld (ix+$00),$24         ; 05E9: dd 36 00 24  Timer A MSBs
	rst $30                 ; 05ED: f7           
	ld (ix+$01),h           ; 05EE: dd 74 01     
	rst $28                 ; 05F1: ef           
	ld (ix+$00),$25         ; 05F2: dd 36 00 25  Timer A LSBs
	rst $30                 ; 05F6: f7           
	ld (ix+$01),l           ; 05F7: dd 75 01     
	rst $28                 ; 05FA: ef           
	ret                     ; 05FB: c9           

; Note 0 (unused) + C..B block 0 (F-num), note 13 overwritten by generator
FreqTableInit:
	defw $00                ; 05FC: 00 00        
	defw $28E               ; 05FE: 8e 02        
	defw $2B4               ; 0600: b4 02        
	defw $2DE               ; 0602: de 02        
	defw $309               ; 0604: 09 03        
	defw $337               ; 0606: 37 03        
	defw $368               ; 0608: 68 03        
	defw $39C               ; 060A: 9c 03        
	defw $3D3               ; 060C: d3 03        
	defw $40E               ; 060E: 0e 04        
	defw $44C               ; 0610: 4c 04        
	defw GetNote_Add        ; 0612: 8d 04        
	defw $4D2               ; 0614: d2 04        
