; Strider II (E) - Mega Drive
; Tiertex sound driver (Z80 side), by Donald Campbell - revision with portamento (cmd F3)
; Source: ROM $0327D8-$032F13 ($73C bytes), copied to Z80 RAM $0000 by 68k LoadSoundDriver ($03279E)
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
	ld hl,FreqTableInit     ; 003A: 21 21 07     
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
	jp Z80_Main             ; 0057: c3 23 06     
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
	call KeyOff             ; 00C5: cd 7b 02     key off FM6, restore its voice
	xor a                   ; 00C8: af           
	ld (DAC_Finished),a     ; 00C9: 32 ed 09     
	ld a,(ix+$00)           ; 00CC: dd 7e 00     
	or (ix+$01)             ; 00CF: dd b6 01     
	jr z,UpdFM6_RestoreMusic; 00D2: 28 05        
	call ReloadVoice        ; 00D4: cd 60 02     
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
	call ReloadVoice        ; 00E3: cd 60 02     
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
	call KeyOff             ; 011D: cd 7b 02     
	ld a,(ix+$00)           ; 0120: dd 7e 00     
	or (ix+$01)             ; 0123: dd b6 01     
	call nz,ReloadVoice     ; 0126: c4 60 02     
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
	call DAC_Output         ; 0144: cd 61 06     yes: output a DAC sample now
	ld (DAC_SaveHL),hl      ; 0147: 22 e2 09     
	ld (DAC_SaveLen),bc     ; 014A: ed 43 e0 09  
	pop ix                  ; 014E: dd e1        
	pop hl                  ; 0150: e1           
	pop de                  ; 0151: d1           
	pop bc                  ; 0152: c1           

UT_CheckPause:
	ld a,(Paused)           ; 0153: 3a ee 09     paused?
	and a                   ; 0156: a7           
	jp nz,PauseChannel      ; 0157: c2 8c 02     
	ld a,(PausedPrev)       ; 015A: 3a ef 09     just un-paused?
	and a                   ; 015D: a7           
	call nz,ReloadVoice     ; 015E: c4 60 02     
	ld a,(ix+$07)           ; 0161: dd 7e 07     start request (68k writes 1)
	and a                   ; 0164: a7           
	jr z,UT_Tick            ; 0165: 28 39        
	dec a                   ; 0167: 3d           
	jr nz,UT_Tick           ; 0168: 20 36        
	call KeyOff             ; 016A: cd 7b 02     
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
	jp z,Seq_ReadNext       ; 01B1: ca bd 04     0 -> read next event
	ld a,d                  ; 01B4: 7a           
	and a                   ; 01B5: a7           
	jr nz,UT_StoreDelay     ; 01B6: 20 0b        
	ld a,e                  ; 01B8: 7b           
	dec a                   ; 01B9: 3d           
	jr nz,UT_StoreDelay     ; 01BA: 20 07        
	ld a,(ix+$21)           ; 01BC: dd 7e 21     1 tick left: key off unless legato
	and a                   ; 01BF: a7           
	call z,KeyOff           ; 01C0: cc 7b 02     

UT_StoreDelay:
	dec de                  ; 01C3: 1b           
	ld (ix+$02),e           ; 01C4: dd 73 02     
	ld (ix+$03),d           ; 01C7: dd 72 03     

; [Strider II] per-tick portamento: IX+$22 steps left, IX+$25/26 step, IX+$23/24 F-num, IX+$27 block<<3.
; F-num space wraps at $28E/$4D2 (octave = $244 units) with block -/+ 1.
UT_Glide:
	ld a,(ix+$22)           ; 01CA: dd 7e 22     glide active?
	and a                   ; 01CD: a7           
	jp z,UT_Return          ; 01CE: ca 5f 02     
	dec a                   ; 01D1: 3d           
	ld (ix+$22),a           ; 01D2: dd 77 22     
	exx                     ; 01D5: d9           
	push hl                 ; 01D6: e5           
	push de                 ; 01D7: d5           
	ld l,(ix+$25)           ; 01D8: dd 6e 25     F-num += step
	ld h,(ix+$26)           ; 01DB: dd 66 26     
	ld e,(ix+$23)           ; 01DE: dd 5e 23     
	ld d,(ix+$24)           ; 01E1: dd 56 24     
	and a                   ; 01E4: a7           
	adc hl,de               ; 01E5: ed 5a        
	ld (ix+$23),l           ; 01E7: dd 75 23     
	ld (ix+$24),h           ; 01EA: dd 74 24     
	ld de,$028E             ; 01ED: 11 8e 02     below $28E?
	and a                   ; 01F0: a7           
	sbc hl,de               ; 01F1: ed 52        
	jr c,Glide_WrapDown     ; 01F3: 38 21        
	ld l,(ix+$23)           ; 01F5: dd 6e 23     
	ld h,(ix+$24)           ; 01F8: dd 66 24     
	ld de,$04D2             ; 01FB: 11 d2 04     >= $4D2?
	and a                   ; 01FE: a7           
	sbc hl,de               ; 01FF: ed 52        
	jr c,Glide_Write        ; 0201: 38 2b        
	ld de,$028E             ; 0203: 11 8e 02     wrap: F-num - $244, block + 1
	and a                   ; 0206: a7           
	adc hl,de               ; 0207: ed 5a        
	ld (ix+$23),l           ; 0209: dd 75 23     
	ld (ix+$24),h           ; 020C: dd 74 24     
	ld a,(ix+$27)           ; 020F: dd 7e 27     
	add a,$08               ; 0212: c6 08        
	jr Glide_SetBlock       ; 0214: 18 11        

Glide_WrapDown:
	ld de,$04D2             ; 0216: 11 d2 04     wrap: F-num + $244, block - 1
	and a                   ; 0219: a7           
	adc hl,de               ; 021A: ed 5a        
	ld (ix+$23),l           ; 021C: dd 75 23     
	ld (ix+$24),h           ; 021F: dd 74 24     
	ld a,(ix+$27)           ; 0222: dd 7e 27     
	sub $08                 ; 0225: d6 08        

Glide_SetBlock:
	ld (ix+$27),a           ; 0227: dd 77 27     
	ld a,h                  ; 022A: 7c           
	and $07                 ; 022B: e6 07        
	ld h,a                  ; 022D: 67           

Glide_Write:
	pop de                  ; 022E: d1           
	pop hl                  ; 022F: e1           
	ld c,(ix+$23)           ; 0230: dd 4e 23     
	ld l,(ix+$24)           ; 0233: dd 6e 24     
	ld a,(ix+$27)           ; 0236: dd 7e 27     
	or l                    ; 0239: b5           
	ld l,a                  ; 023A: 6f           
	ld a,b                  ; 023B: 78           
	ld (de),a               ; 023C: 12           
	inc de                  ; 023D: 13           
	rst $30                 ; 023E: f7           
	ld a,l                  ; 023F: 7d           
	ld (de),a               ; 0240: 12           
	rst $28                 ; 0241: ef           reg $A4+ch
	dec de                  ; 0242: 1b           
	ld a,b                  ; 0243: 78           
	and $A3                 ; 0244: e6 a3        
	ld (de),a               ; 0246: 12           
	inc de                  ; 0247: 13           
	rst $30                 ; 0248: f7           
	ld a,c                  ; 0249: 79           
	ld (de),a               ; 024A: 12           reg $A0+ch
	dec de                  ; 024B: 1b           
	rst $28                 ; 024C: ef           
	ld c,e                  ; 024D: 4b           
	ld e,$00                ; 024E: 1e 00        
	ld a,$28                ; 0250: 3e 28        
	ld (de),a               ; 0252: 12           
	rst $30                 ; 0253: f7           
	ld a,b                  ; 0254: 78           
	and $03                 ; 0255: e6 03        
	add a,c                 ; 0257: 81           
	add a,c                 ; 0258: 81           
	inc e                   ; 0259: 1c           
	or $F0                  ; 025A: f6 f0        
	ld (de),a               ; 025C: 12           
	ld e,c                  ; 025D: 59           
	exx                     ; 025E: d9           

UT_Return:
	ret                     ; 025F: c9           

; Re-send the voice last loaded on this track (pointer at IX+$1F)
ReloadVoice:
	exx                     ; 0260: d9           
	push bc                 ; 0261: c5           
	push de                 ; 0262: d5           
	push hl                 ; 0263: e5           
	ld a,b                  ; 0264: 78           
	and $03                 ; 0265: e6 03        C = $30 + ch (first operator reg)
	or $30                  ; 0267: f6 30        
	ld c,a                  ; 0269: 4f           
	ld b,$1C                ; 026A: 06 1c        
	ex de,hl                ; 026C: eb           
	ld e,(ix+$1F)           ; 026D: dd 5e 1f     
	ld d,(ix+$20)           ; 0270: dd 56 20     
	call WriteVoice         ; 0273: cd 46 03     
	pop hl                  ; 0276: e1           
	pop de                  ; 0277: d1           
	pop bc                  ; 0278: c1           
	exx                     ; 0279: d9           
	ret                     ; 027A: c9           

; Key-off the current channel (reg $28)
KeyOff:
	exx                     ; 027B: d9           
	ld c,e                  ; 027C: 4b           
	ld a,$28                ; 027D: 3e 28        reg $28
	ld e,$00                ; 027F: 1e 00        
	ld (de),a               ; 0281: 12           
	ld a,b                  ; 0282: 78           
	and $03                 ; 0283: e6 03        
	add a,c                 ; 0285: 81           ch + 4 if part II (E'=2)
	add a,c                 ; 0286: 81           
	inc e                   ; 0287: 1c           
	ld (de),a               ; 0288: 12           
	ld e,c                  ; 0289: 59           
	exx                     ; 028A: d9           
	ret                     ; 028B: c9           

; Paused: load SilentVoice, key off, pan off
PauseChannel:
	exx                     ; 028C: d9           
	push bc                 ; 028D: c5           
	push hl                 ; 028E: e5           
	ld a,b                  ; 028F: 78           
	and $03                 ; 0290: e6 03        
	or $30                  ; 0292: f6 30        
	ld c,a                  ; 0294: 4f           
	ld b,$1C                ; 0295: 06 1c        
	ex de,hl                ; 0297: eb           
	ld de,SilentVoice       ; 0298: 11 b2 02     
	call WriteVoice         ; 029B: cd 46 03     
	ex de,hl                ; 029E: eb           
	pop hl                  ; 029F: e1           
	pop bc                  ; 02A0: c1           
	exx                     ; 02A1: d9           
	call KeyOff             ; 02A2: cd 7b 02     then pan off:
	exx                     ; 02A5: d9           
	ld a,b                  ; 02A6: 78           
	and $03                 ; 02A7: e6 03        
	or $B4                  ; 02A9: f6 b4        
	ld (de),a               ; 02AB: 12           
	inc e                   ; 02AC: 1c           
	xor a                   ; 02AD: af           
	ld (de),a               ; 02AE: 12           
	dec e                   ; 02AF: 1d           
	exx                     ; 02B0: d9           
	ret                     ; 02B1: c9           

; 30-byte voice with TL=$7F, fastest envelope (used for pause)
SilentVoice:
	defb $00                ; 02B2: 00           
	defb $00                ; 02B3: 00           
	defb $00                ; 02B4: 00           
	defb $00                ; 02B5: 00           
	defb $00                ; 02B6: 00           
	defb $FF                ; 02B7: ff           
	defb $FF                ; 02B8: ff           
	defb $FF                ; 02B9: ff           
	defb $FF                ; 02BA: ff           
	defb $1F                ; 02BB: 1f           
	defb $1F                ; 02BC: 1f           
	defb $1F                ; 02BD: 1f           
	defb $1F                ; 02BE: 1f           
	defb $1F                ; 02BF: 1f           
	defb $1F                ; 02C0: 1f           
	defb $1F                ; 02C1: 1f           
	defb $1F                ; 02C2: 1f           
	defb $1F                ; 02C3: 1f           
	defb $1F                ; 02C4: 1f           
	defb $1F                ; 02C5: 1f           
	defb $1F                ; 02C6: 1f           
	defb $FE                ; 02C7: fe           
	defb $FE                ; 02C8: fe           
	defb $FE                ; 02C9: fe           
	defb $FE                ; 02CA: fe           
	defb $00                ; 02CB: 00           
	defb $00                ; 02CC: 00           
	defb $00                ; 02CD: 00           
	defb $00                ; 02CE: 00           
	defb $00                ; 02CF: 00           
	defb $00                ; 02D0: 00           
	defb $00                ; 02D1: 00           

; A = sequence byte >= $80
Seq_Command:
	ld b,a                  ; 02D2: 47           
	cp $A0                  ; 02D3: fe a0        $A0 inline voice
	jr z,Cmd_A0_InlineVoice ; 02D5: 28 33        
	and $E0                 ; 02D7: e6 e0        $80-$9F?
	cp $80                  ; 02D9: fe 80        
	jp nz,Seq_CmdEx         ; 02DB: c2 83 03     
	ld a,b                  ; 02DE: 78           
	and $1F                 ; 02DF: e6 1f        
	cp $1F                  ; 02E1: fe 1f        $9F keysplit
	jr nz,Cmd_Voice         ; 02E3: 20 34        
	inc hl                  ; 02E5: 23           +8 = split note
	ld a,(hl)               ; 02E6: 7e           
	ld (ix+$08),a           ; 02E7: dd 77 08     
	ld (ix+$09),$01         ; 02EA: dd 36 09 01  +9 = current side (1)
	inc hl                  ; 02EE: 23           +A = lo voice
	ld a,(hl)               ; 02EF: 7e           
	ld (ix+$0A),a           ; 02F0: dd 77 0a     
	inc hl                  ; 02F3: 23           +B = lo transpose
	ld a,(hl)               ; 02F4: 7e           
	ld (ix+$0B),a           ; 02F5: dd 77 0b     
	ld (ix+$04),a           ; 02F8: dd 77 04     +4 = active transpose
	inc hl                  ; 02FB: 23           
	ld a,(hl)               ; 02FC: 7e           +C = hi voice
	ld (ix+$0C),a           ; 02FD: dd 77 0c     
	inc hl                  ; 0300: 23           
	ld a,(hl)               ; 0301: 7e           +D = hi transpose
	ld (ix+$0D),a           ; 0302: dd 77 0d     
	ld a,(ix+$0A)           ; 0305: dd 7e 0a     
	jr LoadVoiceNum         ; 0308: 18 13        

Cmd_A0_InlineVoice:
	ld (ix+$08),$00         ; 030A: dd 36 08 00  
	inc hl                  ; 030E: 23           
	push hl                 ; 030F: e5           
	ld de,$001F             ; 0310: 11 1f 00     skip 32 bytes
	add hl,de               ; 0313: 19           
	exx                     ; 0314: d9           
	ld c,h                  ; 0315: 4c           
	pop hl                  ; 0316: e1           
	jr LoadVoicePtr         ; 0317: 18 12        

Cmd_Voice:
	ld (ix+$08),$00         ; 0319: dd 36 08 00  cancel keysplit

; A = voice number -> $0A00 + A*32
LoadVoiceNum:
	exx                     ; 031D: d9           
	ld c,h                  ; 031E: 4c           
	ld l,a                  ; 031F: 6f           HL' = $0A00 + n*32
	ld h,$00                ; 0320: 26 00        
	add hl,hl               ; 0322: 29           
	add hl,hl               ; 0323: 29           
	add hl,hl               ; 0324: 29           
	add hl,hl               ; 0325: 29           
	add hl,hl               ; 0326: 29           
	ld a,$0A                ; 0327: 3e 0a        
	add a,h                 ; 0329: 84           
	ld h,a                  ; 032A: 67           

LoadVoicePtr:
	push bc                 ; 032B: c5           
	ld a,b                  ; 032C: 78           
	and $03                 ; 032D: e6 03        
	or $30                  ; 032F: f6 30        
	ld c,a                  ; 0331: 4f           
	ld b,$1C                ; 0332: 06 1c        
	ex de,hl                ; 0334: eb           
	call WriteVoiceSave     ; 0335: cd 40 03     
	ex de,hl                ; 0338: eb           
	pop bc                  ; 0339: c1           
	ld h,c                  ; 033A: 61           
	exx                     ; 033B: d9           
	inc hl                  ; 033C: 23           
	jp Seq_ReadNext         ; 033D: c3 bd 04     

; Remember voice pointer in IX+$1F/$20, then write it
WriteVoiceSave:
	ld (ix+$1F),e           ; 0340: dd 73 1f     
	ld (ix+$20),d           ; 0343: dd 72 20     

; DE = 30-byte voice: [B0 FB/ALG] [28 bytes regs $30-$9C, 4 slots each] [B4 pan/AMS/FMS, 0=>$C0]
WriteVoice:
	ld a,$28                ; 0346: 3e 28        key off first
	ld (YM_A0),a            ; 0348: 32 00 40     
	ld a,c                  ; 034B: 79           
	and $03                 ; 034C: e6 03        
	add a,l                 ; 034E: 85           
	add a,l                 ; 034F: 85           
	ld (YM_D0),a            ; 0350: 32 01 40     
	ld a,c                  ; 0353: 79           
	and $03                 ; 0354: e6 03        
	or $B0                  ; 0356: f6 b0        reg $B0+ch (FB/ALG)
	ld (hl),a               ; 0358: 77           
	rst $30                 ; 0359: f7           
	ld a,(de)               ; 035A: 1a           
	inc de                  ; 035B: 13           
	inc hl                  ; 035C: 23           
	ld (hl),a               ; 035D: 77           
	dec hl                  ; 035E: 2b           
	rst $28                 ; 035F: ef           

WriteVoice_Loop:
	ld (hl),c               ; 0360: 71           
	rst $30                 ; 0361: f7           
	ld a,c                  ; 0362: 79           
	add a,$04               ; 0363: c6 04        
	ld c,a                  ; 0365: 4f           
	ld a,(de)               ; 0366: 1a           
	inc de                  ; 0367: 13           
	inc hl                  ; 0368: 23           
	ld (hl),a               ; 0369: 77           
	dec hl                  ; 036A: 2b           
	rst $28                 ; 036B: ef           
	djnz WriteVoice_Loop    ; 036C: 10 f2        28 operator registers
	ld a,c                  ; 036E: 79           
	and $03                 ; 036F: e6 03        
	or $B4                  ; 0371: f6 b4        reg $B4+ch
	ld (hl),a               ; 0373: 77           
	rst $30                 ; 0374: f7           
	inc hl                  ; 0375: 23           
	ld a,(de)               ; 0376: 1a           
	and a                   ; 0377: a7           
	jr nz,WriteVoice_Pan    ; 0378: 20 02        
	ld a,$C0                ; 037A: 3e c0        0 => L+R

WriteVoice_Pan:
	ld (hl),a               ; 037C: 77           
	ld (ix+$1E),a           ; 037D: dd 77 1e     IX+$1E = pan
	dec hl                  ; 0380: 2b           
	rst $28                 ; 0381: ef           
	ret                     ; 0382: c9           

; $A1-$EE: 1-byte no-op, $EF: freq base, $F0-$FF: jump table
Seq_CmdEx:
	ld a,b                  ; 0383: 78           
	cp $EF                  ; 0384: fe ef        $EF?
	jp z,Cmd_EF_FreqBase    ; 0386: ca 6d 04     
	jp c,Cmd_Nop            ; 0389: da 77 04     $A1-$EE: skip
	push de                 ; 038C: d5           
	sub $F0                 ; 038D: d6 f0        
	add a,a                 ; 038F: 87           
	ld de,CmdJumpTable      ; 0390: 11 a2 03     
	add a,e                 ; 0393: 83           
	ld e,a                  ; 0394: 5f           
	adc a,d                 ; 0395: 8a           
	sub e                   ; 0396: 93           
	ld d,a                  ; 0397: 57           
	ld a,(de)               ; 0398: 1a           
	ld b,a                  ; 0399: 47           
	inc de                  ; 039A: 13           
	ld a,(de)               ; 039B: 1a           
	ld e,b                  ; 039C: 58           
	ld d,a                  ; 039D: 57           
	ex de,hl                ; 039E: eb           
	ex (sp),hl              ; 039F: e3           
	ex de,hl                ; 03A0: eb           
	ret                     ; 03A1: c9           

; $F0..$FF
CmdJumpTable:
	defw Cmd_Nop            ; 03A2: 77 04        
	defw Cmd_Nop            ; 03A4: 77 04        
	defw Cmd_Nop            ; 03A6: 77 04        
	defw Cmd_F3_Glide       ; 03A8: c2 03        
	defw Cmd_F4_Cue68k      ; 03AA: cb 03        
	defw Cmd_F5_Legato      ; 03AC: ed 03        
	defw Cmd_F6_FixedDur    ; 03AE: 02 04        
	defw Cmd_F7_DurFrac     ; 03B0: 7a 04        
	defw Cmd_F8_Return      ; 03B2: 0b 04        
	defw Cmd_F9_Call        ; 03B4: 22 04        
	defw Cmd_FA_DurFracClear; 03B6: 80 04        
	defw Cmd_FB_DurFracLoop ; 03B8: 9e 04        
	defw Cmd_FC_LoopStart   ; 03BA: a1 04        
	defw Cmd_FD_LoopEnd     ; 03BC: af 04        
	defw Cmd_FE_Stop        ; 03BE: 45 04        
	defw Cmd_FF_Restart     ; 03C0: f9 03        

; [Strider II] F3 n: glide from current pitch into the next note over 2^n ticks
Cmd_F3_Glide:
	inc hl                  ; 03C2: 23           
	ld a,(hl)               ; 03C3: 7e           
	ld (ix+$22),a           ; 03C4: dd 77 22     IX+$22 = shift n
	inc hl                  ; 03C7: 23           
	jp Seq_ReadNext         ; 03C8: c3 bd 04     

; Bank = $1FF (68k $FF8000) and write 1 to $FFFF => sets 68k byte $FFFFFF = 1
Cmd_F4_Cue68k:
	push hl                 ; 03CB: e5           
	push de                 ; 03CC: d5           
	push bc                 ; 03CD: c5           
	ld hl,$01FF             ; 03CE: 21 ff 01     bank = $1FF, 9 bits LSB first
	ld de,BankReg           ; 03D1: 11 00 60     
	ld b,$09                ; 03D4: 06 09        
	ld c,$01                ; 03D6: 0e 01        

Cue68k_BankLoop:
	ld a,l                  ; 03D8: 7d           
	and c                   ; 03D9: a1           
	ld (de),a               ; 03DA: 12           
	srl h                   ; 03DB: cb 3c        
	rr l                    ; 03DD: cb 1d        
	djnz Cue68k_BankLoop    ; 03DF: 10 f7        
	pop bc                  ; 03E1: c1           
	pop de                  ; 03E2: d1           
	pop hl                  ; 03E3: e1           
	inc hl                  ; 03E4: 23           
	ld a,$01                ; 03E5: 3e 01        
	ld (Bank_LastByte),a    ; 03E7: 32 ff ff     68k $FFFFFF = 1
	jp Seq_ReadNext         ; 03EA: c3 bd 04     

; Toggle IX+$21 (no key-off before next note)
Cmd_F5_Legato:
	ld a,(ix+$21)           ; 03ED: dd 7e 21     
	xor $FF                 ; 03F0: ee ff        
	ld (ix+$21),a           ; 03F2: dd 77 21     
	inc hl                  ; 03F5: 23           
	jp Seq_ReadNext         ; 03F6: c3 bd 04     

; Jump to track start (IX+5/6)
Cmd_FF_Restart:
	ld l,(ix+$05)           ; 03F9: dd 6e 05     
	ld h,(ix+$06)           ; 03FC: dd 66 06     
	jp Seq_ReadNext         ; 03FF: c3 bd 04     

; IX+$1D = n; while non-zero notes carry no duration byte
Cmd_F6_FixedDur:
	inc hl                  ; 0402: 23           
	ld a,(hl)               ; 0403: 7e           
	ld (ix+$1D),a           ; 0404: dd 77 1d     IX+$1D fixed duration
	inc hl                  ; 0407: 23           
	jp Seq_ReadNext         ; 0408: c3 bd 04     

; End of called block: repeat or return
Cmd_F8_Return:
	dec (ix+$1B)            ; 040B: dd 35 1b     IX+$1B call count
	jr z,Cmd_F8_Done        ; 040E: 28 09        
	ld l,(ix+$19)           ; 0410: dd 6e 19     jump back to called block
	ld h,(ix+$1A)           ; 0413: dd 66 1a     
	jp Seq_ReadNext         ; 0416: c3 bd 04     

Cmd_F8_Done:
	ld l,(ix+$17)           ; 0419: dd 6e 17     return after F9
	ld h,(ix+$18)           ; 041C: dd 66 18     
	jp Seq_ReadNext         ; 041F: c3 bd 04     

; F9 count transpose offs16(LE, relative to offset field)
Cmd_F9_Call:
	inc hl                  ; 0422: 23           
	ld a,(hl)               ; 0423: 7e           
	ld (ix+$1B),a           ; 0424: dd 77 1b     IX+$1B = count
	inc hl                  ; 0427: 23           
	ld a,(hl)               ; 0428: 7e           
	ld (ix+$1C),a           ; 0429: dd 77 1c     IX+$1C = transpose
	inc hl                  ; 042C: 23           
	push de                 ; 042D: d5           
	push hl                 ; 042E: e5           
	ld e,(hl)               ; 042F: 5e           
	inc hl                  ; 0430: 23           
	ld d,(hl)               ; 0431: 56           
	inc hl                  ; 0432: 23           
	ld (ix+$17),l           ; 0433: dd 75 17     IX+$17/18 = return address
	ld (ix+$18),h           ; 0436: dd 74 18     
	pop hl                  ; 0439: e1           
	add hl,de               ; 043A: 19           target = &offset + offset
	ld (ix+$19),l           ; 043B: dd 75 19     IX+$19/1A = target
	ld (ix+$1A),h           ; 043E: dd 74 1a     
	pop de                  ; 0441: d1           
	jp Seq_ReadNext         ; 0442: c3 bd 04     

; Stop track, pan off, key off
Cmd_FE_Stop:
	ld (ix+$00),$00         ; 0445: dd 36 00 00  track pointer = 0
	ld (ix+$01),$00         ; 0449: dd 36 01 00  
	exx                     ; 044D: d9           
	ld a,b                  ; 044E: 78           
	and $03                 ; 044F: e6 03        
	or $B4                  ; 0451: f6 b4        reg $B4+ch = 0
	ld (de),a               ; 0453: 12           
	rst $30                 ; 0454: f7           
	inc e                   ; 0455: 1c           
	xor a                   ; 0456: af           
	ld (de),a               ; 0457: 12           
	ld (ix+$1E),a           ; 0458: dd 77 1e     
	dec e                   ; 045B: 1d           
	rst $28                 ; 045C: ef           
	ld a,$28                ; 045D: 3e 28        key off
	ld c,e                  ; 045F: 4b           
	ld e,$00                ; 0460: 1e 00        
	ld (de),a               ; 0462: 12           
	inc e                   ; 0463: 1c           
	rst $30                 ; 0464: f7           
	ld a,b                  ; 0465: 78           
	and $03                 ; 0466: e6 03        
	ld (de),a               ; 0468: 12           
	ld e,c                  ; 0469: 59           
	rst $28                 ; 046A: ef           
	exx                     ; 046B: d9           
	ret                     ; 046C: c9           

; EF lo hi: note becomes raw F-num/block offset added to this base
Cmd_EF_FreqBase:
	inc hl                  ; 046D: 23           
	ld a,(hl)               ; 046E: 7e           
	ld (ix+$11),a           ; 046F: dd 77 11     IX+$11/12 = freq base (0 = use table)
	inc hl                  ; 0472: 23           
	ld a,(hl)               ; 0473: 7e           
	ld (ix+$12),a           ; 0474: dd 77 12     

Cmd_Nop:
	inc hl                  ; 0477: 23           
	jr Seq_ReadNext         ; 0478: 18 43        

; F7 lo hi: fractional duration add per note (16.16 accumulator)
Cmd_F7_DurFrac:
	call ReadDurFrac        ; 047A: cd 93 04     
	inc hl                  ; 047D: 23           
	jr Seq_ReadNext         ; 047E: 18 3d        

Cmd_FA_DurFracClear:
	inc hl                  ; 0480: 23           
	ld (ix+$15),$00         ; 0481: dd 36 15 00  clear duration fraction
	ld (ix+$16),$00         ; 0485: dd 36 16 00  
	ld (ix+$13),$00         ; 0489: dd 36 13 00  
	ld (ix+$14),$00         ; 048D: dd 36 14 00  
	jr Seq_ReadNext         ; 0491: 18 2a        

ReadDurFrac:
	inc hl                  ; 0493: 23           
	ld a,(hl)               ; 0494: 7e           
	ld (ix+$15),a           ; 0495: dd 77 15     
	inc hl                  ; 0498: 23           
	ld a,(hl)               ; 0499: 7e           
	ld (ix+$16),a           ; 049A: dd 77 16     
	ret                     ; 049D: c9           

; FB lo hi n = F7 lo hi + FC n
Cmd_FB_DurFracLoop:
	call ReadDurFrac        ; 049E: cd 93 04     

; FC n
Cmd_FC_LoopStart:
	inc hl                  ; 04A1: 23           
	ld a,(hl)               ; 04A2: 7e           
	inc hl                  ; 04A3: 23           
	ld (ix+$0E),a           ; 04A4: dd 77 0e     IX+$0E loop count
	ld (ix+$0F),l           ; 04A7: dd 75 0f     IX+$0F/10 loop address
	ld (ix+$10),h           ; 04AA: dd 74 10     
	jr Seq_ReadNext         ; 04AD: 18 0e        

Cmd_FD_LoopEnd:
	inc hl                  ; 04AF: 23           
	dec (ix+$0E)            ; 04B0: dd 35 0e     loop count
	jr z,Seq_ReadNext       ; 04B3: 28 08        
	ld l,(ix+$0F)           ; 04B5: dd 6e 0f     
	ld h,(ix+$10)           ; 04B8: dd 66 10     
	jr Seq_ReadNext         ; 04BB: 18 00        

; Parse sequence bytes until a note/rest (which sets a new delay)
Seq_ReadNext:
	ld a,(hl)               ; 04BD: 7e           
	bit 7,a                 ; 04BE: cb 7f        command?
	jp nz,Seq_Command       ; 04C0: c2 d2 02     
	ld c,a                  ; 04C3: 4f           
	ld a,(ix+$08)           ; 04C4: dd 7e 08     keysplit active?
	and a                   ; 04C7: a7           
	jr z,Note_Play          ; 04C8: 28 3c        
	ld b,a                  ; 04CA: 47           
	ld a,c                  ; 04CB: 79           
	sub b                   ; 04CC: 90           A = (note >= split)
	ld a,$01                ; 04CD: 3e 01        
	sbc a,$00               ; 04CF: de 00        
	cp (ix+$09)             ; 04D1: dd be 09     same side as before?
	jr z,Note_Play          ; 04D4: 28 30        
	ld (ix+$09),a           ; 04D6: dd 77 09     
	and a                   ; 04D9: a7           
	jr nz,KeySplit_Hi       ; 04DA: 20 0b        
	ld a,(ix+$0B)           ; 04DC: dd 7e 0b     
	ld (ix+$04),a           ; 04DF: dd 77 04     
	ld a,(ix+$0A)           ; 04E2: dd 7e 0a     
	jr KeySplit_Reload      ; 04E5: 18 09        

KeySplit_Hi:
	ld a,(ix+$0D)           ; 04E7: dd 7e 0d     
	ld (ix+$04),a           ; 04EA: dd 77 04     
	ld a,(ix+$0C)           ; 04ED: dd 7e 0c     

KeySplit_Reload:
	dec hl                  ; 04F0: 2b           
	jp LoadVoiceNum         ; 04F1: c3 1d 03     

Note_Rest:
	exx                     ; 04F4: d9           
	ld c,e                  ; 04F5: 4b           
	ld e,$00                ; 04F6: 1e 00        
	ld a,$28                ; 04F8: 3e 28        
	ld (de),a               ; 04FA: 12           
	inc e                   ; 04FB: 1c           
	ld a,b                  ; 04FC: 78           
	and $03                 ; 04FD: e6 03        
	add a,c                 ; 04FF: 81           
	add a,c                 ; 0500: 81           
	ld (de),a               ; 0501: 12           
	ld e,c                  ; 0502: 59           
	jp Note_Duration        ; 0503: c3 e6 05     

Note_Play:
	ld a,(ix+$11)           ; 0506: dd 7e 11     raw F-num mode?
	or (ix+$12)             ; 0509: dd b6 12     
	jr z,Note_TableFreq     ; 050C: 28 22        
	call GetNote            ; 050E: cd 1e 05     
	jr z,Note_Rest          ; 0511: 28 e1        
	exx                     ; 0513: d9           
	add a,(ix+$11)          ; 0514: dd 86 11     F-num = note + base
	ld c,a                  ; 0517: 4f           
	adc a,(ix+$12)          ; 0518: dd 8e 12     
	sub c                   ; 051B: 91           
	jr Note_GlideCheck      ; 051C: 18 1d        

; A = note + call-transpose (if in F9 call) + voice transpose; Z set if rest
GetNote:
	ld a,c                  ; 051E: 79           
	and a                   ; 051F: a7           
	jr z,GetNote_Ret        ; 0520: 28 0d        
	ld a,(ix+$1B)           ; 0522: dd 7e 1b     
	and a                   ; 0525: a7           
	jr z,GetNote_Add        ; 0526: 28 03        
	ld a,(ix+$1C)           ; 0528: dd 7e 1c     

GetNote_Add:
	add a,c                 ; 052B: 81           
	add a,(ix+$04)          ; 052C: dd 86 04     

GetNote_Ret:
	ret                     ; 052F: c9           

Note_TableFreq:
	call GetNote            ; 0530: cd 1e 05     
	jr z,Note_Rest          ; 0533: 28 bf        
	add a,a                 ; 0535: 87           index into FreqTable
	exx                     ; 0536: d9           
	ld l,a                  ; 0537: 6f           
	ld c,(hl)               ; 0538: 4e           
	inc l                   ; 0539: 2c           
	ld a,(hl)               ; 053A: 7e           

Note_GlideCheck:
	ld l,a                  ; 053B: 6f           
	ld a,(ix+$22)           ; 053C: dd 7e 22     glide requested?
	and a                   ; 053F: a7           
	jr nz,Glide_Setup       ; 0540: 20 08        
	ld (ix+$23),c           ; 0542: dd 71 23     no: remember F-num as current pitch
	ld (ix+$24),l           ; 0545: dd 75 24     
	jr Note_WriteFreqKeyOn  ; 0548: 18 79        

; [Strider II] next note with glide: step = (target - current)/2^n, normalised to the current block
Glide_Setup:
	push hl                 ; 054A: e5           
	push de                 ; 054B: d5           
	ld a,(ix+$24)           ; 054C: dd 7e 24     current block
	and $38                 ; 054F: e6 38        
	ld (ix+$27),a           ; 0551: dd 77 27     
	ld e,(ix+$23)           ; 0554: dd 5e 23     
	ld a,(ix+$24)           ; 0557: dd 7e 24     
	and $07                 ; 055A: e6 07        
	ld (ix+$24),a           ; 055C: dd 77 24     
	ld d,a                  ; 055F: 57           
	ld a,l                  ; 0560: 7d           
	and $07                 ; 0561: e6 07        
	ld h,a                  ; 0563: 67           
	ld a,l                  ; 0564: 7d           
	and $38                 ; 0565: e6 38        
	ld l,c                  ; 0567: 69           
	push de                 ; 0568: d5           
	push hl                 ; 0569: e5           
	ld e,(ix+$27)           ; 056A: dd 5e 27     
	sub e                   ; 056D: 93           
	jr z,Glide_SameBlock    ; 056E: 28 2a        
	jr c,Glide_TargetLower  ; 0570: 38 13        
	srl a                   ; 0572: cb 3f        
	srl a                   ; 0574: cb 3f        
	srl a                   ; 0576: cb 3f        
	ld de,$0244             ; 0578: 11 44 02     +$244 per octave of difference

Glide_OctUp:
	and a                   ; 057B: a7           
	adc hl,de               ; 057C: ed 5a        
	dec a                   ; 057E: 3d           
	jr nz,Glide_OctUp       ; 057F: 20 fa        
	pop de                  ; 0581: d1           
	pop de                  ; 0582: d1           
	jr Glide_Delta          ; 0583: 18 17        

Glide_TargetLower:
	neg                     ; 0585: ed 44        
	srl a                   ; 0587: cb 3f        
	srl a                   ; 0589: cb 3f        
	srl a                   ; 058B: cb 3f        
	ld de,$0244             ; 058D: 11 44 02     

Glide_OctDown:
	and a                   ; 0590: a7           
	sbc hl,de               ; 0591: ed 52        
	dec a                   ; 0593: 3d           
	jr nz,Glide_OctDown     ; 0594: 20 fa        
	pop de                  ; 0596: d1           
	pop de                  ; 0597: d1           
	jr Glide_Delta          ; 0598: 18 02        

Glide_SameBlock:
	pop hl                  ; 059A: e1           
	pop de                  ; 059B: d1           

Glide_Delta:
	and a                   ; 059C: a7           
	sbc hl,de               ; 059D: ed 52        
	ld a,(ix+$22)           ; 059F: dd 7e 22     
	ld e,$01                ; 05A2: 1e 01        E = 2^n (step counter)

Glide_ShiftLoop:
	sra h                   ; 05A4: cb 2c        
	rr l                    ; 05A6: cb 1d        
	sla e                   ; 05A8: cb 23        
	dec a                   ; 05AA: 3d           
	jr nz,Glide_ShiftLoop   ; 05AB: 20 f7        
	ld (ix+$22),e           ; 05AD: dd 73 22     IX+$22 = steps
	ld (ix+$25),l           ; 05B0: dd 75 25     IX+$25/26 = step
	ld (ix+$26),h           ; 05B3: dd 74 26     
	pop de                  ; 05B6: d1           
	pop hl                  ; 05B7: e1           
	ld c,(ix+$23)           ; 05B8: dd 4e 23     write current (start) pitch
	ld l,(ix+$24)           ; 05BB: dd 6e 24     
	ld a,(ix+$27)           ; 05BE: dd 7e 27     
	or l                    ; 05C1: b5           

Note_WriteFreqKeyOn:
	ld l,a                  ; 05C2: 6f           

Note_WriteFreqKeyOn:
	ld a,b                  ; 05C3: 78           reg $A4+ch (block/F-num hi)
	ld (de),a               ; 05C4: 12           
	inc de                  ; 05C5: 13           
	rst $30                 ; 05C6: f7           
	ld a,l                  ; 05C7: 7d           
	ld (de),a               ; 05C8: 12           
	rst $28                 ; 05C9: ef           
	dec de                  ; 05CA: 1b           
	ld a,b                  ; 05CB: 78           
	and $A3                 ; 05CC: e6 a3        reg $A0+ch
	ld (de),a               ; 05CE: 12           
	inc de                  ; 05CF: 13           
	rst $30                 ; 05D0: f7           
	ld a,c                  ; 05D1: 79           
	ld (de),a               ; 05D2: 12           
	dec de                  ; 05D3: 1b           
	rst $28                 ; 05D4: ef           
	ld c,e                  ; 05D5: 4b           
	ld e,$00                ; 05D6: 1e 00        
	ld a,$28                ; 05D8: 3e 28        key on: reg $28 = $F0|ch
	ld (de),a               ; 05DA: 12           
	rst $30                 ; 05DB: f7           
	ld a,b                  ; 05DC: 78           
	and $03                 ; 05DD: e6 03        
	add a,c                 ; 05DF: 81           
	add a,c                 ; 05E0: 81           
	inc e                   ; 05E1: 1c           
	or $F0                  ; 05E2: f6 f0        
	ld (de),a               ; 05E4: 12           
	ld e,c                  ; 05E5: 59           

Note_Duration:
	exx                     ; 05E6: d9           
	inc hl                  ; 05E7: 23           
	ld a,(ix+$1D)           ; 05E8: dd 7e 1d     fixed duration?
	and a                   ; 05EB: a7           
	jr z,Note_ReadDur       ; 05EC: 28 03        
	ld e,a                  ; 05EE: 5f           
	jr Note_StoreDur        ; 05EF: 18 12        

Note_ReadDur:
	ld a,(hl)               ; 05F1: 7e           duration byte
	inc hl                  ; 05F2: 23           
	ld e,a                  ; 05F3: 5f           

Note_DurExt:
	ld a,(hl)               ; 05F4: 7e           
	cp $7F                  ; 05F5: fe 7f        $7F xx: add xx to duration
	jr nz,Note_StoreDur     ; 05F7: 20 0a        
	inc hl                  ; 05F9: 23           
	ld a,(hl)               ; 05FA: 7e           
	add a,e                 ; 05FB: 83           
	ld e,a                  ; 05FC: 5f           
	adc a,d                 ; 05FD: 8a           
	sub e                   ; 05FE: 93           
	ld d,a                  ; 05FF: 57           
	inc hl                  ; 0600: 23           
	jr Note_DurExt          ; 0601: 18 f1        

Note_StoreDur:
	ld (ix+$00),l           ; 0603: dd 75 00     
	ld (ix+$01),h           ; 0606: dd 74 01     
	ld l,(ix+$13)           ; 0609: dd 6e 13     fraction accumulator +$13/14 += +$15/16
	ld h,(ix+$14)           ; 060C: dd 66 14     
	ld c,(ix+$15)           ; 060F: dd 4e 15     
	ld b,(ix+$16)           ; 0612: dd 46 16     
	add hl,bc               ; 0615: 09           
	ld (ix+$13),l           ; 0616: dd 75 13     
	ld (ix+$14),h           ; 0619: dd 74 14     
	jp nc,UT_StoreDelay     ; 061C: d2 c3 01     
	inc de                  ; 061F: 13           carry: one extra tick
	jp UT_StoreDelay        ; 0620: c3 c3 01     

; Timer B = $DD (tick), Timer A from DAC_TimerA; poll timers forever
Z80_Main:
	ld ix,YM_A0             ; 0623: dd 21 00 40  
	ld (ix+$00),$26         ; 0627: dd 36 00 26  reg $26 Timer B = $DD
	rst $30                 ; 062B: f7           
	ld (ix+$01),$DD         ; 062C: dd 36 01 dd  
	rst $28                 ; 0630: ef           
	ld hl,$FE00             ; 0631: 21 00 fe     default Timer A ($3F8)
	call SetTimerA          ; 0634: cd 0e 07     
	ld (ix+$00),$27         ; 0637: dd 36 00 27  reg $27 = $3F: load+enable A,B, reset flags
	rst $30                 ; 063B: f7           
	ld (ix+$01),$3F         ; 063C: dd 36 01 3f  
	rst $28                 ; 0640: ef           
	ld hl,YM_A0             ; 0641: 21 00 40     
	ld bc,$0000             ; 0644: 01 00 00     
	ld (hl),$27             ; 0647: 36 27        
	call TimerB_Tick        ; 0649: cd c7 06     

MainLoop:
	ld (hl),$27             ; 064C: 36 27        

ML_WaitBusy:
	ld a,(hl)               ; 064E: 7e           
	bit 7,a                 ; 064F: cb 7f        wait not busy
	jr nz,ML_WaitBusy       ; 0651: 20 fb        

ML_WaitTimer:
	ld a,(hl)               ; 0653: 7e           
	and $03                 ; 0654: e6 03        wait for a timer flag
	jr z,ML_WaitTimer       ; 0656: 28 fb        
	and $02                 ; 0658: e6 02        Timer B has priority
	jr nz,TimerB_Tick       ; 065A: 20 6b        
	call DAC_Output         ; 065C: cd 61 06     
	jr MainLoop             ; 065F: 18 eb        

; Timer A overflow: output one sample (BC = remaining, IY = pointer)
DAC_Output:
	inc l                   ; 0661: 2c           
	ld (hl),$1F             ; 0662: 36 1f        reg $27 = $1F: reset Timer A flag
	dec l                   ; 0664: 2d           
	ld a,(Paused)           ; 0665: 3a ee 09     paused: no DAC
	and a                   ; 0668: a7           
	ret nz                  ; 0669: c0           
	ld a,(DAC_Active)       ; 066A: 3a f0 09     already playing?
	and a                   ; 066D: a7           
	jr nz,DAC_WriteSample   ; 066E: 20 15        
	ld a,b                  ; 0670: 78           nothing queued
	or c                    ; 0671: b1           
	ret z                   ; 0672: c8           
	ld a,$01                ; 0673: 3e 01        
	ld (DAC_Active),a       ; 0675: 32 f0 09     
	ld (hl),$2B             ; 0678: 36 2b        reg $2B = $80 DAC on; $B6 = $C0 FM6 pan L+R
	inc l                   ; 067A: 2c           
	ld (hl),$80             ; 067B: 36 80        
	inc l                   ; 067D: 2c           
	ld (hl),$B6             ; 067E: 36 b6        
	inc l                   ; 0680: 2c           
	ld (hl),$C0             ; 0681: 36 c0        
	ld l,$00                ; 0683: 2e 00        

DAC_WriteSample:
	ld (hl),$2A             ; 0685: 36 2a        reg $2A DAC data
	ld a,(DAC_HalfVol)      ; 0687: 3a e4 09     music playing -> half volume
	and a                   ; 068A: a7           
	jr z,DAC_FullVol        ; 068B: 28 11        
	ld a,(iy+$00)           ; 068D: fd 7e 00     
	inc l                   ; 0690: 2c           
	push bc                 ; 0691: c5           
	srl a                   ; 0692: cb 3f        sample >> 1 (SUB result unused)
	ld b,a                  ; 0694: 47           
	srl a                   ; 0695: cb 3f        
	srl a                   ; 0697: cb 3f        
	sub b                   ; 0699: 90           
	ld a,b                  ; 069A: 78           
	pop bc                  ; 069B: c1           
	jr DAC_Store            ; 069C: 18 04        

DAC_FullVol:
	ld a,(iy+$00)           ; 069E: fd 7e 00     
	inc l                   ; 06A1: 2c           

DAC_Store:
	ld (hl),a               ; 06A2: 77           
	inc iy                  ; 06A3: fd 23        
	dec l                   ; 06A5: 2d           
	dec bc                  ; 06A6: 0b           
	ld a,b                  ; 06A7: 78           
	or c                    ; 06A8: b1           
	ret nz                  ; 06A9: c0           
	ld (hl),$2B             ; 06AA: 36 2b        end of sample: reg $2B
	inc l                   ; 06AC: 2c           
	push hl                 ; 06AD: e5           
	ld hl,(DAC_LoopBank)    ; 06AE: 2a fe 09     loop bank set?
	ld a,h                  ; 06B1: 7c           
	or l                    ; 06B2: b5           
	jr z,DAC_Stop           ; 06B3: 28 06        
	call DAC_StartSample    ; 06B5: cd ec 06     
	pop hl                  ; 06B8: e1           
	dec l                   ; 06B9: 2d           
	ret                     ; 06BA: c9           

DAC_Stop:
	pop hl                  ; 06BB: e1           
	ld (DAC_Active),a       ; 06BC: 32 f0 09     DAC_Active = 0; $2B = 0 DAC off
	ld (hl),a               ; 06BF: 77           
	ld a,$01                ; 06C0: 3e 01        tell channel update to restore FM6
	ld (DAC_Finished),a     ; 06C2: 32 ed 09     
	dec l                   ; 06C5: 2d           
	ret                     ; 06C6: c9           

; Music/SFX tick, then start a newly requested sample
TimerB_Tick:
	ld (DAC_SaveHL),hl      ; 06C7: 22 e2 09     
	ld (DAC_SaveLen),bc     ; 06CA: ed 43 e0 09  
	inc l                   ; 06CE: 2c           
	ld (hl),$2F             ; 06CF: 36 2f        reg $27 = $2F: reset Timer B flag
	ld a,(PauseReq)         ; 06D1: 3a f1 09     latch pause request
	ld (Paused),a           ; 06D4: 32 ee 09     
	call UpdateAllChannels  ; 06D7: cd 69 00     
	ld bc,(DAC_SaveLen)     ; 06DA: ed 4b e0 09  
	ld hl,(DAC_Bank)        ; 06DE: 2a fc 09     new sample requested?
	ld a,h                  ; 06E1: 7c           
	or l                    ; 06E2: b5           
	call nz,DAC_StartSample ; 06E3: c4 ec 06     
	ld hl,(DAC_SaveHL)      ; 06E6: 2a e2 09     
	jp MainLoop             ; 06E9: c3 4c 06     

; HL = 9-bit bank. Set bank, clear trigger, load IY/BC, program Timer A
DAC_StartSample:
	ld ix,YM_A0             ; 06EC: dd 21 00 40  
	ld de,BankReg           ; 06F0: 11 00 60     Z80 bank register
	ld b,$09                ; 06F3: 06 09        
	ld c,$01                ; 06F5: 0e 01        

DSS_BankLoop:
	ld a,l                  ; 06F7: 7d           
	and c                   ; 06F8: a1           
	ld (de),a               ; 06F9: 12           
	srl h                   ; 06FA: cb 3c        
	rr l                    ; 06FC: cb 1d        
	djnz DSS_BankLoop       ; 06FE: 10 f7        
	ld (DAC_Bank),hl        ; 0700: 22 fc 09     store remaining bits (0) -> clears trigger
	ld iy,(DAC_Addr)        ; 0703: fd 2a f8 09  
	ld bc,(DAC_Len)         ; 0707: ed 4b fa 09  
	ld hl,(DAC_TimerA)      ; 070B: 2a f6 09     

; H -> reg $24, L -> reg $25
SetTimerA:
	ld (ix+$00),$24         ; 070E: dd 36 00 24  Timer A MSBs
	rst $30                 ; 0712: f7           
	ld (ix+$01),h           ; 0713: dd 74 01     
	rst $28                 ; 0716: ef           
	ld (ix+$00),$25         ; 0717: dd 36 00 25  Timer A LSBs
	rst $30                 ; 071B: f7           
	ld (ix+$01),l           ; 071C: dd 75 01     
	rst $28                 ; 071F: ef           
	ret                     ; 0720: c9           

; Note 0 (unused) + C..B block 0 (F-num), note 13 overwritten by generator
FreqTableInit:
	defw $00                ; 0721: 00 00        
	defw $28E               ; 0723: 8e 02        
	defw $2B4               ; 0725: b4 02        
	defw $2DE               ; 0727: de 02        
	defw $309               ; 0729: 09 03        
	defw $337               ; 072B: 37 03        
	defw $368               ; 072D: 68 03        
	defw $39C               ; 072F: 9c 03        
	defw $3D3               ; 0731: d3 03        
	defw $40E               ; 0733: 0e 04        
	defw $44C               ; 0735: 4c 04        
	defw $48D               ; 0737: 8d 04        
	defw $4D2               ; 0739: d2 04        
	defb $00                ; 073B: 00           
