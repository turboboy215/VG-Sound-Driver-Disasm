; Generated from the ROM by tools/zdis.py + z80_v3.py (labels/comments hand-written).
; Syntax: z80dasm-style; numbers $hex.

VoiceBank:              equ  $0400
YM_A0:                  equ  $4000
YM_D0:                  equ  $4001
YM_A1:                  equ  $4002
YM_D1:                  equ  $4003
BankReg:                equ  $6000

	org	$0C00


; ==========================================================================
;  Krisalis / Shaun Hollingworth Mega Drive sound driver -- Z80 side
;  Revision 3 (Boogerman (E), Mickey Mania (E)); identical in both games.
;    Boogerman:    ROM $098D54 -> Z80 $0C00 ($1400 bytes copied, $0C64 used)
;    Mickey Mania: ROM $1E1086 -> Z80 $0C00
;  The 68k does all sequencing (once per frame); the Z80 receives one
;  "row" (6 pattern cells) or a tick command per frame through the mailbox
;  at MB_Cmd and drives the YM2612 plus one PCM channel (FM6/DAC).
;  In this revision the DAC player is polled from everywhere
;  (exx / ld a,b / or c / call nz,DAC_Poll) so the sample keeps running
;  while voices are loaded and pitches updated.
;
;  Channel state (IY, 14 bytes, ChanState + ch*14):
;    +00/01 slide step (signed, F-number units)    +02/03 current pitch (block<<11|fnum, bit 14 = key on)
;    +04/05 target pitch (portamento)              +06    portamento speed (cmd $7A)
;    +07    -                                      +08    voice (CH_VOICE)
;    +09    voice currently in the YM (CH_LOADED)  +0A    -
;    +0B    FMS override (cmd $7C)                 +0C    pan override (cmd $7B)
;    +0D    re-trigger flag (0 = legato)
;  Alternate registers while a sample plays: HL' = pointer, BC' = bytes left,
;  D' = rate, E' = phase accumulator.
; ==========================================================================
Start:
	di                                         ; 0C00  F3           reset entry (68k writes DI / JP $0C00 at Z80 $0000 after uploading the driver)
	im     1                                   ; 0C01  ED 56
	ld     sp,$1FFF                            ; 0C03  31 FF 1F
	ld     hl,Init_RstVectors                  ; 0C06  21 4F 0C     copy RST $08/$10/$18/$20 handlers to $0008-$003E
	ld     de,$0008                            ; 0C09  11 08 00
	ld     bc,$0037                            ; 0C0C  01 37 00
	ldir                                       ; 0C0F  ED B0
	ld     hl,Init_IntVector                   ; 0C11  21 6F 0C     copy "ei / ret" interrupt stub to $0038 (IM 1, interrupts never enabled)
	ld     de,$0038                            ; 0C14  11 38 00
	ld     bc,$0008                            ; 0C17  01 08 00
	ldir                                       ; 0C1A  ED B0
	ld     hl,Init_Vec0000                     ; 0C1C  21 49 0C     copy "nop / jp $0C00 / dw MB_Cmd" to $0000-$0005
	ld     de,$0000                            ; 0C1F  11 00 00
	ld     bc,$0006                            ; 0C22  01 06 00
	ldir                                       ; 0C25  ED B0
	call   YM_Init                             ; 0C27  CD AF 14     LFO on (6.02 Hz), Timer/CH3 mode off
	exx                                        ; 0C2A  D9           BC' = 0: no sample playing (alternate set = DAC player state)
	ld     bc,$0000                            ; 0C2B  01 00 00
	ld     a,$B6                               ; 0C2E  3E B6        FM6 pan register byte in RegTable = $B6 (redirected to $28 while a sample plays)
	ld     (RegTable+$0173),a                  ; 0C30  32 2F 0F
	exx                                        ; 0C33  D9
	ld     (ChanState+$09),a                   ; 0C34  32 45 0F     CH_LOADED of all 6 channels = $B6 (invalid -> forces voice reload)
	ld     (ChanState+$17),a                   ; 0C37  32 53 0F
	ld     (ChanState+$25),a                   ; 0C3A  32 61 0F
	ld     (ChanState+$33),a                   ; 0C3D  32 6F 0F
	ld     (ChanState+$41),a                   ; 0C40  32 7D 0F
	ld     (ChanState+$4F),a                   ; 0C43  32 8B 0F
	jp     MainLoop                            ; 0C46  C3 F3 0F
Init_Vec0000:
	db     $00,$C3,$00,$0C,$AC,$0F             ; 0C49  -> $0000: nop / jp Start / dw MB_Cmd ($0004 = mailbox pointer read by the 68k)
Init_RstVectors:
	db     $3A,$00,$40,$CB,$7F,$20,$01,$C9     ; 0C4F  -> $0008 RST 08h: if YM busy fall into RST 10h; $0010 RST 10h: wait YM ready; $0018 RST 18h: DAC service (unused); $0020 RST 20h: wait YM ready
	db     $3A,$00,$40,$CB,$7F,$20,$F9,$C9     ; 0C57
	db     $D9,$79,$B0,$C4,$4C,$17,$D9,$C9     ; 0C5F
	db     $3A,$00,$40,$CB,$7F,$20,$F9,$C9     ; 0C67
Init_IntVector:
	db     $FB,$C9                             ; 0C6F  -> $0038: ei / ret

; --------------------------------------------------------------------------
;  LoadChannelVoice: A = voice, C = channel, IY = channel state
;  FM5 during a jingle: load with jingle volume, mark MB_JingleState=$FE,
;  then apply the jingle pan to register $B5.
; --------------------------------------------------------------------------
LoadChannelVoice:
	ld     (iy+$09),a                          ; 0C71  FD 77 09     CH_LOADED = voice number
	ex     af,af'                              ; 0C74  08
	exx                                        ; 0C75  D9
	ld     a,b                                 ; 0C76  78
	or     c                                   ; 0C77  B1
	call   nz,DAC_Poll                         ; 0C78  C4 4C 17
	exx                                        ; 0C7B  D9
	xor    a                                   ; 0C7C  AF
	ld     (LoadVoice_jflag+1),a               ; 0C7D  32 F4 0C     patch LoadVoice: "ld a,0" -> 0 = use music volume
	ld     a,c                                 ; 0C80  79           FM5 while a jingle is active?
	cp     $04                                 ; 0C81  FE 04
	jr     nz,LoadVoice                        ; 0C83  20 37
	ld     a,(MB_JingleState)                  ; 0C85  3A AD 0F
	or     a                                   ; 0C88  B7
	jr     z,LoadVoice                         ; 0C89  28 31
	ld     a,$01                               ; 0C8B  3E 01        patch LoadVoice: "ld a,1" -> use jingle volume
	ld     (LoadVoice_jflag+1),a               ; 0C8D  32 F4 0C
	call   LoadVoice                           ; 0C90  CD BC 0C
	push   ix                                  ; 0C93  DD E5
	ld     a,$FE                               ; 0C95  3E FE        jingle state $FE = jingle voice loaded on FM5
	ld     (MB_JingleState),a                  ; 0C97  32 AD 0F
	ld     l,$C0                               ; 0C9A  2E C0        default pan L+R
	ld     a,(MB_JinglePan)                    ; 0C9C  3A EC 0F     jingle pan from the 68k (0 = leave voice pan)
	or     a                                   ; 0C9F  B7
	jr     z,LoadChannelVoice_done             ; 0CA0  28 17
	and    $C0                                 ; 0CA2  E6 C0
	ld     l,a                                 ; 0CA4  6F
	ld     a,$B5                               ; 0CA5  3E B5        part II reg $B5 = FM5 pan/AMS/FMS
	ld     (YM_A1),a                           ; 0CA7  32 02 40
	rst    $10                                 ; 0CAA  D7
	ld     ix,(CurVoicePtr)                    ; 0CAB  DD 2A 9A 0D  keep AMS/FMS of the voice, replace pan bits
	ld     a,(ix+$19)                          ; 0CAF  DD 7E 19
	and    $3F                                 ; 0CB2  E6 3F
	or     l                                   ; 0CB4  B5
	ld     (YM_D1),a                           ; 0CB5  32 03 40
	rst    $10                                 ; 0CB8  D7
LoadChannelVoice_done:
	pop    ix                                  ; 0CB9  DD E1
	ret                                        ; 0CBB  C9

; --------------------------------------------------------------------------
;  LoadVoice: write a 32-byte voice (26 registers) to channel C.
;  Voice layout: +00..03 DT/MUL, +04..07 TL, +08..0B KS/AR, +0C..0F AM/D1R,
;  +10..13 D2R, +14..17 D1L/RR (operator order 1,3,2,4), +18 FB/ALG,
;  +19 pan/AMS/FMS, +1A scratch (pan copy), +1B..1F unused.
; --------------------------------------------------------------------------
LoadVoice:
	ex     af,af'                              ; 0CBC  08           A = voice number (bit 7 set = silent voice), C = channel 0-5
	push   bc                                  ; 0CBD  C5
	ld     de,VoiceBank                        ; 0CBE  11 00 04
	ld     h,$00                               ; 0CC1  26 00
	ld     l,a                                 ; 0CC3  6F
	add    hl,hl                               ; 0CC4  29
	add    hl,hl                               ; 0CC5  29
	add    hl,hl                               ; 0CC6  29
	add    hl,hl                               ; 0CC7  29
	add    hl,hl                               ; 0CC8  29
	add    hl,de                               ; 0CC9  19           HL = $0400 + voice*32 (voice bank uploaded by the 68k)
	bit    7,a                                 ; 0CCA  CB 7F
	jr     z,LoadVoice_havevoice               ; 0CCC  28 03
	ld     hl,SilentVoice                      ; 0CCE  21 9C 0D     bit 7: silent voice (TL=$7F)
LoadVoice_havevoice:
	ld     (CurVoicePtr),hl                    ; 0CD1  22 9A 0D
	exx                                        ; 0CD4  D9
	ld     a,b                                 ; 0CD5  78
	or     c                                   ; 0CD6  B1
	call   nz,DAC_Poll                         ; 0CD7  C4 4C 17
	exx                                        ; 0CDA  D9
	ex     de,hl                               ; 0CDB  EB           DE = voice data
	ld     b,c                                 ; 0CDC  41           BC = channel*64
	ld     c,$00                               ; 0CDD  0E 00
	srl    b                                   ; 0CDF  CB 38
	rr     c                                   ; 0CE1  CB 19
	srl    b                                   ; 0CE3  CB 38
	rr     c                                   ; 0CE5  CB 19
	ld     hl,RegTable                         ; 0CE7  21 BC 0D     HL = register list for this channel (32 x port,reg)
	add    hl,bc                               ; 0CEA  09
	ld     b,$40                               ; 0CEB  06 40
	ex     af,af'                              ; 0CED  08
	ld     a,$04                               ; 0CEE  3E 04        4 x DT/MUL ($30-$3C)
	call   WriteRegList                        ; 0CF0  CD 80 0D
LoadVoice_jflag:
	ld     a,$00                               ; 0CF3  3E 00        SELF-MODIFIED by LoadChannelVoice: 1 = jingle channel
	or     a                                   ; 0CF5  B7
	jr     z,LoadVoice_musicvol                ; 0CF6  28 08
	ld     a,(MB_JingleVol)                    ; 0CF8  3A E8 0F     jingle volume
	or     a                                   ; 0CFB  B7
	jr     z,LoadVoice_novolume                ; 0CFC  28 2A
	jr     LoadVoice_withvolume                ; 0CFE  18 06
LoadVoice_musicvol:
	ld     a,(MB_MusicVol)                     ; 0D00  3A E6 0F     music volume
	or     a                                   ; 0D03  B7
	jr     z,LoadVoice_novolume                ; 0D04  28 22        volume 0 -> write TLs straight from the voice
LoadVoice_withvolume:
	push   iy                                  ; 0D06  FD E5
	push   bc                                  ; 0D08  C5
	push   de                                  ; 0D09  D5
	ld     (WriteTL_Carrier_vol+1),a           ; 0D0A  32 9D 11     patch the volume into WriteTL_Carrier
	ld     iy,(CurVoicePtr)                    ; 0D0D  FD 2A 9A 0D
	call   ApplyVolume                         ; 0D11  CD 09 11     write the 4 TLs with carrier attenuation
	pop    de                                  ; 0D14  D1
	pop    bc                                  ; 0D15  C1
	pop    iy                                  ; 0D16  FD E1
	inc    de                                  ; 0D18  13           skip the 4 TL bytes / 4 TL register entries
	inc    de                                  ; 0D19  13
	inc    de                                  ; 0D1A  13
	inc    de                                  ; 0D1B  13
	inc    hl                                  ; 0D1C  23
	inc    hl                                  ; 0D1D  23
	inc    hl                                  ; 0D1E  23
	inc    hl                                  ; 0D1F  23
	inc    hl                                  ; 0D20  23
	inc    hl                                  ; 0D21  23
	inc    hl                                  ; 0D22  23
	inc    hl                                  ; 0D23  23
	ld     a,$12                               ; 0D24  3E 12        18 registers left ($50-$8C, $B0, $B4)
	jr     LoadVoice_write                     ; 0D26  18 02
LoadVoice_novolume:
	ld     a,$16                               ; 0D28  3E 16        22 registers ($40-$8C, $B0, $B4)
LoadVoice_write:
	call   WriteVoiceRegs                      ; 0D2A  CD 2F 0D
	pop    bc                                  ; 0D2D  C1
	ret                                        ; 0D2E  C9
WriteVoiceRegs:
	cp     $01                                 ; 0D2F  FE 01        A = number of registers still to write; the last one ($B4) gets the overrides
	jr     nz,WriteVoiceRegs_notlast           ; 0D31  20 2D
	ex     af,af'                              ; 0D33  08           last register = $B4 pan/AMS/FMS
	ld     a,(de)                              ; 0D34  1A           copy voice byte $19 to scratch byte $1A and modify the copy
	inc    de                                  ; 0D35  13
	ld     (de),a                              ; 0D36  12
	ld     a,(iy+$0B)                          ; 0D37  FD 7E 0B     FMS override (cmd $7C) or pan override (cmd $7B)?
	or     (iy+$0C)                            ; 0D3A  FD B6 0C
	jr     z,WriteVoiceRegs_out                ; 0D3D  28 22
	ld     a,(iy+$0B)                          ; 0D3F  FD 7E 0B
	ld     c,a                                 ; 0D42  4F
	or     a                                   ; 0D43  B7
	jr     z,WriteVoiceRegs_pan                ; 0D44  28 05
	ld     a,(de)                              ; 0D46  1A           FMS = override (LFO vibrato depth)
	and    $F8                                 ; 0D47  E6 F8
	or     c                                   ; 0D49  B1
	ld     (de),a                              ; 0D4A  12
WriteVoiceRegs_pan:
	exx                                        ; 0D4B  D9
	ld     a,b                                 ; 0D4C  78
	or     c                                   ; 0D4D  B1
	call   nz,DAC_Poll                         ; 0D4E  C4 4C 17
	exx                                        ; 0D51  D9
	ld     a,(iy+$0C)                          ; 0D52  FD 7E 0C
	ld     c,a                                 ; 0D55  4F
	or     a                                   ; 0D56  B7
	jr     z,WriteVoiceRegs_out                ; 0D57  28 08
	ld     a,(de)                              ; 0D59  1A           pan bits = override
	and    $3F                                 ; 0D5A  E6 3F
	or     c                                   ; 0D5C  B1
	ld     (de),a                              ; 0D5D  12
	jr     WriteVoiceRegs_out                  ; 0D5E  18 01
WriteVoiceRegs_notlast:
	ex     af,af'                              ; 0D60  08
WriteVoiceRegs_out:
	exx                                        ; 0D61  D9
	ld     a,b                                 ; 0D62  78
	or     c                                   ; 0D63  B1
	call   nz,DAC_Poll                         ; 0D64  C4 4C 17
	exx                                        ; 0D67  D9
	ld     c,(hl)                              ; 0D68  4E           C = YM port low byte (0 = part I, 2 = part II), A = register
	inc    hl                                  ; 0D69  23
	ld     a,(hl)                              ; 0D6A  7E
	inc    hl                                  ; 0D6B  23
	ld     (bc),a                              ; 0D6C  02           B = $40 -> YM address port
	rst    $10                                 ; 0D6D  D7
	inc    c                                   ; 0D6E  0C
	ld     a,(de)                              ; 0D6F  1A
	ld     (bc),a                              ; 0D70  02           data port
	rst    $10                                 ; 0D71  D7
	exx                                        ; 0D72  D9
	ld     a,b                                 ; 0D73  78
	or     c                                   ; 0D74  B1
	call   nz,DAC_Poll                         ; 0D75  C4 4C 17
	exx                                        ; 0D78  D9
	inc    de                                  ; 0D79  13
	ex     af,af'                              ; 0D7A  08
	dec    a                                   ; 0D7B  3D
	jr     nz,WriteVoiceRegs                   ; 0D7C  20 B1
	ex     af,af'                              ; 0D7E  08
	ret                                        ; 0D7F  C9
WriteRegList:
	ex     af,af'                              ; 0D80  08
	ld     c,(hl)                              ; 0D81  4E
	inc    hl                                  ; 0D82  23
	ld     a,(hl)                              ; 0D83  7E
	inc    hl                                  ; 0D84  23
	ld     (bc),a                              ; 0D85  02
	rst    $10                                 ; 0D86  D7
	inc    c                                   ; 0D87  0C
	ld     a,(de)                              ; 0D88  1A
	ld     (bc),a                              ; 0D89  02
	rst    $10                                 ; 0D8A  D7
	inc    de                                  ; 0D8B  13
	exx                                        ; 0D8C  D9
	ld     a,b                                 ; 0D8D  78
	or     c                                   ; 0D8E  B1
	call   nz,DAC_Poll                         ; 0D8F  C4 4C 17
	exx                                        ; 0D92  D9
	ex     af,af'                              ; 0D93  08
	dec    a                                   ; 0D94  3D
	jr     nz,WriteRegList                     ; 0D95  20 E9
	ex     af,af'                              ; 0D97  08
	ret                                        ; 0D98  C9
	db     $00                                 ; 0D99

; ---------------------------------------------------------------------- data
CurVoicePtr:
	dw     $0000                               ; 0D9A  pointer to the voice last loaded by LoadVoice
SilentVoice:
	db     $00,$00,$00,$00,$7F,$7F,$7F,$7F     ; 0D9C  "voice $80": all TL = $7F
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0DA4
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0DAC
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0DB4
RegTable:
	db     $00,$30,$00,$34,$00,$38,$00,$3C,$00,$40,$00,$44,$00,$48,$00,$4C; 0DBC  FM1: 32 x (port,reg): $30..$3C,$40..$4C,$50..$5C,$60..$6C,$70..$7C,$80..$8C,$B0,$B4,-,-,$90..$9C (only 26 used)
	db     $00,$50,$00,$54,$00,$58,$00,$5C,$00,$60,$00,$64,$00,$68,$00,$6C; 0DCC
	db     $00,$70,$00,$74,$00,$78,$00,$7C,$00,$80,$00,$84,$00,$88,$00,$8C; 0DDC
	db     $00,$B0,$00,$B4,$00,$00,$00,$00,$00,$90,$00,$94,$00,$98,$00,$9C; 0DEC
	db     $00,$31,$00,$35,$00,$39,$00,$3D,$00,$41,$00,$45,$00,$49,$00,$4D; 0DFC  FM2
	db     $00,$51,$00,$55,$00,$59,$00,$5D,$00,$61,$00,$65,$00,$69,$00,$6D; 0E0C
	db     $00,$71,$00,$75,$00,$79,$00,$7D,$00,$81,$00,$85,$00,$89,$00,$8D; 0E1C
	db     $00,$B1,$00,$B5,$00,$00,$00,$00,$00,$91,$00,$95,$00,$99,$00,$9D; 0E2C
	db     $00,$32,$00,$36,$00,$3A,$00,$3E,$00,$42,$00,$46,$00,$4A,$00,$4E; 0E3C  FM3
	db     $00,$52,$00,$56,$00,$5A,$00,$5E,$00,$62,$00,$66,$00,$6A,$00,$6E; 0E4C
	db     $00,$72,$00,$76,$00,$7A,$00,$7E,$00,$82,$00,$86,$00,$8A,$00,$8E; 0E5C
	db     $00,$B2,$00,$B6,$00,$00,$00,$00,$00,$92,$00,$96,$00,$9A,$00,$9E; 0E6C
	db     $02,$30,$02,$34,$02,$38,$02,$3C,$02,$40,$02,$44,$02,$48,$02,$4C; 0E7C  FM4 (part II)
	db     $02,$50,$02,$54,$02,$58,$02,$5C,$02,$60,$02,$64,$02,$68,$02,$6C; 0E8C
	db     $02,$70,$02,$74,$02,$78,$02,$7C,$02,$80,$02,$84,$02,$88,$02,$8C; 0E9C
	db     $02,$B0,$02,$B4,$00,$00,$00,$00,$02,$90,$02,$94,$02,$98,$02,$9C; 0EAC
	db     $02,$31,$02,$35,$02,$39,$02,$3D,$02,$41,$02,$45,$02,$49,$02,$4D; 0EBC  FM5
	db     $02,$51,$02,$55,$02,$59,$02,$5D,$02,$61,$02,$65,$02,$69,$02,$6D; 0ECC
	db     $02,$71,$02,$75,$02,$79,$02,$7D,$02,$81,$02,$85,$02,$89,$02,$8D; 0EDC
	db     $02,$B1,$02,$B5,$00,$00,$00,$00,$02,$91,$02,$95,$02,$99,$02,$9D; 0EEC
	db     $02,$32,$02,$36,$02,$3A,$02,$3E,$02,$42,$02,$46,$02,$4A,$02,$4E; 0EFC  FM6: the $B6 byte at $0F2F is patched to $28 while a sample plays
	db     $02,$52,$02,$56,$02,$5A,$02,$5E,$02,$62,$02,$66,$02,$6A,$02,$6E; 0F0C
	db     $02,$72,$02,$76,$02,$7A,$02,$7E,$02,$82,$02,$86,$02,$8A,$02,$8E; 0F1C
	db     $02,$B2,$02,$B6,$00,$00,$00,$00,$02,$92,$02,$96,$02,$9A,$02,$9E; 0F2C

; ---------------------------------------------------------------------- RAM
;  ChanState: 6 x 14 bytes (FM1..FM6)
ChanState:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F3C  6 x 14 bytes, see header
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F4A
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F58
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F66
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F74
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F82
Unused_0F90:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F90
Cmd3_ChanState:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F9E  scratch channel state used by command 3

; --------------------------------------------------------------------------
;  Mailbox (68k writes with the bus held; its address is read from $0004)
; --------------------------------------------------------------------------
MB_Cmd:
	db     $00                                 ; 0FAC  68k command: 1 tick, 2 reset, 3 load voice, 4 silence, 7 reload voices, other (10) = new row
MB_JingleState:
	db     $00                                 ; 0FAD  0 = no jingle; $FF = jingle playing on FM5 (68k); $FE = jingle voice loaded (Z80)
MB_Notes:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0FAE  6 pattern cells (lo,hi) for FM1-FM6; FM5 holds the jingle cell while a jingle plays
MB_VoiceBankHi:
	db     $00                                 ; 0FBA  cmd $7D bit 7 for music: voices 32-63
MB_JingleBankHi:
	db     $00                                 ; 0FBB  cmd $7D bit 7 for the jingle
MB_SmpAddr:
	dw     $1863                               ; 0FBC  sample start ($8000 | offset in bank)
MB_SmpRate:
	db     $58                                 ; 0FBE  sample rate step (phase increment per poll, /256)
MB_SmpPhase:
	db     $00                                 ; 0FBF  initial phase (never written by the 68k)
MB_SmpLen:
	dw     $09A2                               ; 0FC0  sample length (bytes)
MB_SmpTrigger:
	db     $00                                 ; 0FC2  non-zero = start an SFX sample (68k)
MB_Pad_17:
	db     $00                                 ; 0FC3
MB_SampleTable:
	db     $00,$00,$00,$00                     ; 0FC4  8 x (addr.hi, addr.lo, len.hi, len.lo), big-endian copy of the module sample table
	db     $00,$00,$00,$00                     ; 0FC8
	db     $00,$00,$00,$00                     ; 0FCC
	db     $00,$00,$00,$00                     ; 0FD0
	db     $00,$00,$00,$00                     ; 0FD4
	db     $00,$00,$00,$00                     ; 0FD8
	db     $00,$00,$00,$00                     ; 0FDC
	db     $00,$00,$00,$00                     ; 0FE0
MB_SFXBusy:
	db     $00                                 ; 0FE4  $FF while an SFX sample plays (music drums are ignored)
MB_Pad_39:
	db     $00                                 ; 0FE5
MB_MusicVol:
	db     $00                                 ; 0FE6  music attenuation added to carrier TLs (0 = full volume)
MB_Pad_3B:
	db     $00                                 ; 0FE7
MB_JingleVol:
	db     $00                                 ; 0FE8  jingle attenuation
MB_Pad_3D:
	db     $00                                 ; 0FE9
MB_SFXPan:
	db     $00                                 ; 0FEA  SFX sample pan (0 = centre)
MB_Pad_3F:
	db     $00                                 ; 0FEB
MB_JinglePan:
	db     $00                                 ; 0FEC  jingle pan (0 = voice pan)
MB_Pad_41:
	db     $00                                 ; 0FED
MB_SFXBank:
	db     $00                                 ; 0FEE  ROM bank (addr>>15) of the SFX sample
MB_Pad_43:
	db     $00                                 ; 0FEF
MB_MusicBank:
	db     $00                                 ; 0FF0  ROM bank of the music sample table
MB_Pad_45:
	db     $00                                 ; 0FF1
LastJingleState:
	db     $00                                 ; 0FF2  jingle state seen at the previous row (Z80 private)

; --------------------------------------------------------------------------
;  Main loop
; --------------------------------------------------------------------------
MainLoop:
	ld     a,(MB_MusicVol)                     ; 0FF3  3A E6 0F     re-apply music volume after every command (used for fades)
	or     a                                   ; 0FF6  B7
	call   nz,RefreshMusicTL                   ; 0FF7  C4 C9 10
	exx                                        ; 0FFA  D9
	ld     a,b                                 ; 0FFB  78
	or     c                                   ; 0FFC  B1
	call   nz,DAC_Poll                         ; 0FFD  C4 4C 17
	exx                                        ; 1000  D9
	ld     a,(MB_JingleState)                  ; 1001  3A AD 0F     jingle voice loaded?
	cp     $FE                                 ; 1004  FE FE
	call   z,RefreshJingleTL                   ; 1006  CC B4 10     -> keep FM5 at jingle volume
WaitCommand:
	ld     a,(MB_SmpTrigger)                   ; 1009  3A C2 0F
	or     a                                   ; 100C  B7
	call   nz,StartSFXSample                   ; 100D  C4 E0 16     68k requested an SFX sample
	exx                                        ; 1010  D9
	ld     a,b                                 ; 1011  78
	or     c                                   ; 1012  B1
	call   nz,DAC_Poll                         ; 1013  C4 4C 17
	exx                                        ; 1016  D9
	ld     a,(MB_Cmd)                          ; 1017  3A AC 0F     wait for a command, servicing the DAC
	or     a                                   ; 101A  B7
	jr     z,WaitCommand                       ; 101B  28 EC
	ld     c,a                                 ; 101D  4F           acknowledge
	xor    a                                   ; 101E  AF
	ld     (MB_Cmd),a                          ; 101F  32 AC 0F
	exx                                        ; 1022  D9
	ld     a,b                                 ; 1023  78
	or     c                                   ; 1024  B1
	call   nz,DAC_Poll                         ; 1025  C4 4C 17
	exx                                        ; 1028  D9
	ld     a,c                                 ; 1029  79
	cp     $01                                 ; 102A  FE 01        1: tick only
	jr     z,WaitCommand_tick                  ; 102C  28 79
	cp     $02                                 ; 102E  FE 02        2: reset
	jp     z,Cmd2_Reset                        ; 1030  CA AF 15
	cp     $03                                 ; 1033  FE 03
	jr     nz,WaitCommand_not3                 ; 1035  20 10
	ld     a,(MB_Notes+1)                      ; 1037  3A AF 0F     3: load voice MB_Notes[0] on channel MB_Notes[1]
	ld     c,a                                 ; 103A  4F
	ld     a,(MB_Notes)                        ; 103B  3A AE 0F
	ld     iy,Cmd3_ChanState                   ; 103E  FD 21 9E 0F
	call   LoadChannelVoice                    ; 1042  CD 71 0C
	jr     MainLoop                            ; 1045  18 AC
WaitCommand_not3:
	cp     $04                                 ; 1047  FE 04        4: silence
	jr     nz,WaitCommand_not4                 ; 1049  20 05
	call   Cmd4_Silence                        ; 104B  CD 33 15
	jr     MainLoop                            ; 104E  18 A3
WaitCommand_not4:
	cp     $07                                 ; 1050  FE 07        7: reload voices (resume)
	jp     z,Cmd7_ReloadVoices                 ; 1052  CA 86 15
	ld     a,(MB_JingleState)                  ; 1055  3A AD 0F     otherwise: new row
	and    $FE                                 ; 1058  E6 FE
	ld     c,a                                 ; 105A  4F
	exx                                        ; 105B  D9
	ld     a,b                                 ; 105C  78
	or     c                                   ; 105D  B1
	call   nz,DAC_Poll                         ; 105E  C4 4C 17
	exx                                        ; 1061  D9
	ld     a,(LastJingleState)                 ; 1062  3A F2 0F     jingle started or stopped since the last row?
	cp     c                                   ; 1065  B9
	jr     z,WaitCommand_rowloop_init          ; 1066  28 12
	ld     a,c                                 ; 1068  79
	ld     (LastJingleState),a                 ; 1069  32 F2 0F
	ld     iy,ChanState+$38                    ; 106C  FD 21 74 0F  FM5: clear portamento, FMS and pan overrides
	xor    a                                   ; 1070  AF
	ld     (iy+$06),a                          ; 1071  FD 77 06
	ld     (iy+$0B),a                          ; 1074  FD 77 0B
	ld     (iy+$0C),a                          ; 1077  FD 77 0C
WaitCommand_rowloop_init:
	ld     b,$06                               ; 107A  06 06
	ld     c,$00                               ; 107C  0E 00
	ld     ix,MB_Notes                         ; 107E  DD 21 AE 0F  IX = note cells, IY = channel state
	ld     iy,ChanState                        ; 1082  FD 21 3C 0F
WaitCommand_rowloop:
	exx                                        ; 1086  D9
	ld     a,b                                 ; 1087  78
	or     c                                   ; 1088  B1
	call   nz,DAC_Poll                         ; 1089  C4 4C 17
	exx                                        ; 108C  D9
	push   bc                                  ; 108D  C5
	call   DoNoteWord                          ; 108E  CD 8E 13
	inc    ix                                  ; 1091  DD 23
	inc    ix                                  ; 1093  DD 23
	exx                                        ; 1095  D9
	ld     a,b                                 ; 1096  78
	or     c                                   ; 1097  B1
	call   nz,DAC_Poll                         ; 1098  C4 4C 17
	exx                                        ; 109B  D9
	ld     de,$000E                            ; 109C  11 0E 00
	add    iy,de                               ; 109F  FD 19
	pop    bc                                  ; 10A1  C1
	inc    c                                   ; 10A2  0C
	push   af                                  ; 10A3  F5           (timing filler)
	pop    af                                  ; 10A4  F1
	djnz   WaitCommand_rowloop                 ; 10A5  10 DF
WaitCommand_tick:
	exx                                        ; 10A7  D9
	ld     a,b                                 ; 10A8  78
	or     c                                   ; 10A9  B1
	call   nz,DAC_Poll                         ; 10AA  C4 4C 17
	exx                                        ; 10AD  D9
	call   UpdateAllChannels                   ; 10AE  CD BE 11     apply slides / portamento
	jp     MainLoop                            ; 10B1  C3 F3 0F

; --------------------------------------------------------------------------
;  Volume (TL) handling
; --------------------------------------------------------------------------
RefreshJingleTL:
	ld     a,(MB_JingleVol)                    ; 10B4  3A E8 0F     keep the jingle voice on FM5 at jingle volume
	ld     (WriteTL_Carrier_vol+1),a           ; 10B7  32 9D 11
	ld     ix,ChanState+$38                    ; 10BA  DD 21 74 0F
	ld     hl,RegTable+$0108                   ; 10BE  21 C4 0E     TL register entries of FM5
	ld     a,(ix+$08)                          ; 10C1  DD 7E 08
	or     a                                   ; 10C4  B7
	call   p,ApplyVolumeVoice                  ; 10C5  F4 F8 10
	ret                                        ; 10C8  C9
RefreshMusicTL:
	ld     a,(MB_MusicVol)                     ; 10C9  3A E6 0F     rewrite carrier TLs of every channel with MB_MusicVol
	ld     b,$06                               ; 10CC  06 06
	ld     (WriteTL_Carrier_vol+1),a           ; 10CE  32 9D 11
	ld     ix,ChanState                        ; 10D1  DD 21 3C 0F
	ld     hl,RegTable+$08                     ; 10D5  21 C4 0D     TL entries of FM1
RefreshMusicTL_loop:
	push   bc                                  ; 10D8  C5
	ld     a,b                                 ; 10D9  78
	cp     $02                                 ; 10DA  FE 02        FM5 (B=2) is skipped while a jingle owns it
	jr     nz,RefreshMusicTL_do                ; 10DC  20 06
	ld     a,(MB_JingleState)                  ; 10DE  3A AD 0F
	or     a                                   ; 10E1  B7
	jr     nz,RefreshMusicTL_next              ; 10E2  20 07
RefreshMusicTL_do:
	ld     a,(ix+$08)                          ; 10E4  DD 7E 08     voice loaded?
	or     a                                   ; 10E7  B7
	call   p,ApplyVolumeVoice                  ; 10E8  F4 F8 10
RefreshMusicTL_next:
	ld     bc,$000E                            ; 10EB  01 0E 00
	add    ix,bc                               ; 10EE  DD 09
	ld     bc,$0040                            ; 10F0  01 40 00
	add    hl,bc                               ; 10F3  09
	pop    bc                                  ; 10F4  C1
	djnz   RefreshMusicTL_loop                 ; 10F5  10 E1
	ret                                        ; 10F7  C9
ApplyVolumeVoice:
	push   hl                                  ; 10F8  E5           IY = $0400 + A*32
	ld     l,a                                 ; 10F9  6F
	ld     h,$00                               ; 10FA  26 00
	add    hl,hl                               ; 10FC  29
	add    hl,hl                               ; 10FD  29
	add    hl,hl                               ; 10FE  29
	add    hl,hl                               ; 10FF  29
	add    hl,hl                               ; 1100  29
	ld     de,VoiceBank                        ; 1101  11 00 04
	add    hl,de                               ; 1104  19
	push   hl                                  ; 1105  E5
	pop    iy                                  ; 1106  FD E1
	pop    hl                                  ; 1108  E1
ApplyVolume:
	push   hl                                  ; 1109  E5           IY = voice, HL = TL register entries; carriers get +volume
	ld     a,(iy+$18)                          ; 110A  FD 7E 18     FB/ALG
	and    $07                                 ; 110D  E6 07
	or     a                                   ; 110F  B7
	jr     z,ApplyVolume_alg0123               ; 1110  28 2C
	dec    a                                   ; 1112  3D
	jr     z,ApplyVolume_alg0123               ; 1113  28 29
	dec    a                                   ; 1115  3D
	jr     z,ApplyVolume_alg0123               ; 1116  28 26
	dec    a                                   ; 1118  3D
	jr     z,ApplyVolume_alg0123               ; 1119  28 23
	dec    a                                   ; 111B  3D
	jr     z,ApplyVolume_alg4                  ; 111C  28 3A
	dec    a                                   ; 111E  3D
	jr     z,ApplyVolume_alg56                 ; 111F  28 51
	dec    a                                   ; 1121  3D
	jr     z,ApplyVolume_alg56                 ; 1122  28 4E
	ld     a,(iy+$04)                          ; 1124  FD 7E 04     ALG 7: all four operators are carriers
	call   WriteTL_Carrier                     ; 1127  CD 8C 11
	ld     a,(iy+$05)                          ; 112A  FD 7E 05
	call   WriteTL_Carrier                     ; 112D  CD 8C 11
	ld     a,(iy+$06)                          ; 1130  FD 7E 06
	call   WriteTL_Carrier                     ; 1133  CD 8C 11
	ld     a,(iy+$07)                          ; 1136  FD 7E 07
	call   WriteTL_Carrier                     ; 1139  CD 8C 11
	pop    hl                                  ; 113C  E1
	ret                                        ; 113D  C9
ApplyVolume_alg0123:
	ld     a,(iy+$04)                          ; 113E  FD 7E 04     ALG 0-3: only op4 is a carrier
	call   WriteTL_Mod                         ; 1141  CD AA 11
	ld     a,(iy+$05)                          ; 1144  FD 7E 05
	call   WriteTL_Mod                         ; 1147  CD AA 11
	ld     a,(iy+$06)                          ; 114A  FD 7E 06
	call   WriteTL_Mod                         ; 114D  CD AA 11
	ld     a,(iy+$07)                          ; 1150  FD 7E 07
	call   WriteTL_Carrier                     ; 1153  CD 8C 11
	pop    hl                                  ; 1156  E1
	ret                                        ; 1157  C9
ApplyVolume_alg4:
	ld     a,(iy+$04)                          ; 1158  FD 7E 04     ALG 4: op2 and op4
	call   WriteTL_Mod                         ; 115B  CD AA 11
	ld     a,(iy+$05)                          ; 115E  FD 7E 05
	call   WriteTL_Mod                         ; 1161  CD AA 11
	ld     a,(iy+$06)                          ; 1164  FD 7E 06
	call   WriteTL_Carrier                     ; 1167  CD 8C 11
	ld     a,(iy+$07)                          ; 116A  FD 7E 07
	call   WriteTL_Carrier                     ; 116D  CD 8C 11
	pop    hl                                  ; 1170  E1
	ret                                        ; 1171  C9
ApplyVolume_alg56:
	ld     a,(iy+$04)                          ; 1172  FD 7E 04     ALG 5/6: op2, op3, op4
	call   WriteTL_Mod                         ; 1175  CD AA 11
	ld     a,(iy+$05)                          ; 1178  FD 7E 05
	call   WriteTL_Carrier                     ; 117B  CD 8C 11
	ld     a,(iy+$06)                          ; 117E  FD 7E 06
	call   WriteTL_Carrier                     ; 1181  CD 8C 11
	ld     a,(iy+$07)                          ; 1184  FD 7E 07
	call   WriteTL_Carrier                     ; 1187  CD 8C 11
	pop    hl                                  ; 118A  E1
	ret                                        ; 118B  C9
WriteTL_Carrier:
	ld     b,$40                               ; 118C  06 40
	ld     c,(hl)                              ; 118E  4E
	inc    hl                                  ; 118F  23
	push   af                                  ; 1190  F5
	exx                                        ; 1191  D9
	ld     a,b                                 ; 1192  78
	or     c                                   ; 1193  B1
	call   nz,DAC_Poll                         ; 1194  C4 4C 17
	exx                                        ; 1197  D9
	ld     a,(hl)                              ; 1198  7E
	inc    hl                                  ; 1199  23
	ld     (bc),a                              ; 119A  02
	rst    $10                                 ; 119B  D7
WriteTL_Carrier_vol:
	ld     a,$00                               ; 119C  3E 00        SELF-MODIFIED: volume
	ld     e,a                                 ; 119E  5F
	pop    af                                  ; 119F  F1
	add    a,e                                 ; 11A0  83
	bit    7,a                                 ; 11A1  CB 7F        clamp to $7F
	jr     z,WriteTL_Carrier_write             ; 11A3  28 02
	ld     a,$7F                               ; 11A5  3E 7F
WriteTL_Carrier_write:
	inc    c                                   ; 11A7  0C
	ld     (bc),a                              ; 11A8  02
	ret                                        ; 11A9  C9
WriteTL_Mod:
	ld     b,$40                               ; 11AA  06 40
	ld     c,(hl)                              ; 11AC  4E
	inc    hl                                  ; 11AD  23
	push   af                                  ; 11AE  F5
	exx                                        ; 11AF  D9
	ld     a,b                                 ; 11B0  78
	or     c                                   ; 11B1  B1
	call   nz,DAC_Poll                         ; 11B2  C4 4C 17
	exx                                        ; 11B5  D9
	ld     a,(hl)                              ; 11B6  7E
	inc    hl                                  ; 11B7  23
	ld     (bc),a                              ; 11B8  02
	rst    $10                                 ; 11B9  D7
	pop    af                                  ; 11BA  F1
	inc    c                                   ; 11BB  0C
	ld     (bc),a                              ; 11BC  02
	ret                                        ; 11BD  C9

; --------------------------------------------------------------------------
;  Per-tick pitch update: portamento ($7A) or slide (effect nibble)
; --------------------------------------------------------------------------
UpdateAllChannels:
	ld     iy,ChanState                        ; 11BE  FD 21 3C 0F  per-tick update of all 6 channels (DAC serviced in between)
	ld     c,$00                               ; 11C2  0E 00
	ld     b,$06                               ; 11C4  06 06
	call   UpdateChannel                       ; 11C6  CD 30 12
	inc    c                                   ; 11C9  0C
	dec    b                                   ; 11CA  05
	exx                                        ; 11CB  D9
	ld     a,b                                 ; 11CC  78
	or     c                                   ; 11CD  B1
	call   nz,DAC_Poll                         ; 11CE  C4 4C 17
	exx                                        ; 11D1  D9
	ld     iy,ChanState+$0E                    ; 11D2  FD 21 4A 0F
	call   UpdateChannel                       ; 11D6  CD 30 12
	inc    c                                   ; 11D9  0C
	dec    b                                   ; 11DA  05
	exx                                        ; 11DB  D9
	ld     a,b                                 ; 11DC  78
	or     c                                   ; 11DD  B1
	call   nz,DAC_Poll                         ; 11DE  C4 4C 17
	exx                                        ; 11E1  D9
	ld     iy,ChanState+$1C                    ; 11E2  FD 21 58 0F
	call   UpdateChannel                       ; 11E6  CD 30 12
	inc    c                                   ; 11E9  0C
	dec    b                                   ; 11EA  05
	exx                                        ; 11EB  D9
	ld     a,b                                 ; 11EC  78
	or     c                                   ; 11ED  B1
	call   nz,DAC_Poll                         ; 11EE  C4 4C 17
	exx                                        ; 11F1  D9
	ld     iy,ChanState+$2A                    ; 11F2  FD 21 66 0F
	call   UpdateChannel                       ; 11F6  CD 30 12
	inc    c                                   ; 11F9  0C
	dec    b                                   ; 11FA  05
	exx                                        ; 11FB  D9
	ld     a,b                                 ; 11FC  78
	or     c                                   ; 11FD  B1
	call   nz,DAC_Poll                         ; 11FE  C4 4C 17
	exx                                        ; 1201  D9
	ld     iy,ChanState+$38                    ; 1202  FD 21 74 0F
	call   UpdateChannel                       ; 1206  CD 30 12
	inc    c                                   ; 1209  0C
	dec    b                                   ; 120A  05
	exx                                        ; 120B  D9
	ld     a,b                                 ; 120C  78
	or     c                                   ; 120D  B1
	call   nz,DAC_Poll                         ; 120E  C4 4C 17
	exx                                        ; 1211  D9
	ld     iy,ChanState+$46                    ; 1212  FD 21 82 0F
	call   UpdateChannel                       ; 1216  CD 30 12
	exx                                        ; 1219  D9
	ld     a,b                                 ; 121A  78
	or     c                                   ; 121B  B1
	call   nz,DAC_Poll                         ; 121C  C4 4C 17
	exx                                        ; 121F  D9
	ret                                        ; 1220  C9
Porta_Start:
	ld     l,(iy+$04)                          ; 1221  FD 6E 04     first portamento step from silence: jump straight to the target
	ld     h,(iy+$05)                          ; 1224  FD 66 05
	ld     (iy+$02),l                          ; 1227  FD 75 02
	ld     (iy+$03),h                          ; 122A  FD 74 03
	jp     UpdateChannel_writefreq             ; 122D  C3 EB 12
UpdateChannel:
	ld     a,(iy+$06)                          ; 1230  FD 7E 06     IY = channel: portamento if CH_PORTA != 0, else slide
	or     a                                   ; 1233  B7
	jp     z,Slide                             ; 1234  CA FB 12
	ld     l,(iy+$04)                          ; 1237  FD 6E 04     HL = target
	ld     h,(iy+$05)                          ; 123A  FD 66 05
	ld     e,(iy+$02)                          ; 123D  FD 5E 02     DE = current
	ld     d,(iy+$03)                          ; 1240  FD 56 03
	exx                                        ; 1243  D9
	ld     a,b                                 ; 1244  78
	or     c                                   ; 1245  B1
	call   nz,DAC_Poll                         ; 1246  C4 4C 17
	exx                                        ; 1249  D9
	ld     a,d                                 ; 124A  7A           strip the key-on flag
	and    $3F                                 ; 124B  E6 3F
	ld     d,a                                 ; 124D  57
	ld     a,d                                 ; 124E  7A
	or     e                                   ; 124F  B3
	jr     z,Porta_Start                       ; 1250  28 CF
	push   hl                                  ; 1252  E5
	and    a                                   ; 1253  A7
	sbc    hl,de                               ; 1254  ED 52        compare target with current
	pop    hl                                  ; 1256  E1
	jr     z,UpdateChannel_reached             ; 1257  28 04
	jr     nc,UpdateChannel_up                 ; 1259  30 03
	jr     UpdateChannel_down                  ; 125B  18 44
UpdateChannel_reached:
	ret                                        ; 125D  C9
UpdateChannel_up:
	ex     de,hl                               ; 125E  EB           current += speed
	ld     d,$00                               ; 125F  16 00
	ld     e,(iy+$06)                          ; 1261  FD 5E 06
	add    hl,de                               ; 1264  19
	exx                                        ; 1265  D9
	ld     a,b                                 ; 1266  78
	or     c                                   ; 1267  B1
	call   nz,DAC_Poll                         ; 1268  C4 4C 17
	exx                                        ; 126B  D9
	push   hl                                  ; 126C  E5           F-number above $4D0 -> next block, F-num - $269
	ld     a,h                                 ; 126D  7C
	and    $07                                 ; 126E  E6 07
	ld     h,a                                 ; 1270  67
	ld     de,$04D0                            ; 1271  11 D0 04
	and    a                                   ; 1274  A7
	sbc    hl,de                               ; 1275  ED 52
	pop    hl                                  ; 1277  E1
	jr     c,UpdateChannel_upstore             ; 1278  38 0A
	ld     de,$0269                            ; 127A  11 69 02
	and    a                                   ; 127D  A7
	sbc    hl,de                               ; 127E  ED 52
	ld     a,h                                 ; 1280  7C
	add    a,$08                               ; 1281  C6 08
	ld     h,a                                 ; 1283  67
UpdateChannel_upstore:
	ld     (iy+$02),l                          ; 1284  FD 75 02     clamp at target
	ld     (iy+$03),h                          ; 1287  FD 74 03
	ld     e,(iy+$04)                          ; 128A  FD 5E 04
	ld     d,(iy+$05)                          ; 128D  FD 56 05
	and    a                                   ; 1290  A7
	sbc    hl,de                               ; 1291  ED 52
	jr     c,UpdateChannel_upkey               ; 1293  38 06
	ld     (iy+$02),e                          ; 1295  FD 73 02
	ld     (iy+$03),d                          ; 1298  FD 72 03
UpdateChannel_upkey:
	set    6,(iy+$03)                          ; 129B  FD CB 03 F6  key-on flag
	jr     UpdateChannel_writefreq             ; 129F  18 4A
UpdateChannel_down:
	ex     de,hl                               ; 12A1  EB           current -= speed
	ld     d,$00                               ; 12A2  16 00
	ld     e,(iy+$06)                          ; 12A4  FD 5E 06
	and    a                                   ; 12A7  A7
	sbc    hl,de                               ; 12A8  ED 52
	push   hl                                  ; 12AA  E5
	ld     a,h                                 ; 12AB  7C
	and    $07                                 ; 12AC  E6 07
	ld     h,a                                 ; 12AE  67
	exx                                        ; 12AF  D9
	ld     a,b                                 ; 12B0  78
	or     c                                   ; 12B1  B1
	call   nz,DAC_Poll                         ; 12B2  C4 4C 17
	exx                                        ; 12B5  D9
	ld     de,$0269                            ; 12B6  11 69 02     F-number below $269 -> previous block, F-num + $269
	and    a                                   ; 12B9  A7
	sbc    hl,de                               ; 12BA  ED 52
	pop    hl                                  ; 12BC  E1
	jr     nc,UpdateChannel_downstore          ; 12BD  30 08
	ld     de,$0269                            ; 12BF  11 69 02
	add    hl,de                               ; 12C2  19
	ld     a,h                                 ; 12C3  7C
	sub    $08                                 ; 12C4  D6 08
	ld     h,a                                 ; 12C6  67
UpdateChannel_downstore:
	exx                                        ; 12C7  D9
	ld     a,b                                 ; 12C8  78
	or     c                                   ; 12C9  B1
	call   nz,DAC_Poll                         ; 12CA  C4 4C 17
	exx                                        ; 12CD  D9
	ld     (iy+$02),l                          ; 12CE  FD 75 02
	ld     (iy+$03),h                          ; 12D1  FD 74 03
	ld     e,(iy+$04)                          ; 12D4  FD 5E 04
	ld     d,(iy+$05)                          ; 12D7  FD 56 05
	and    a                                   ; 12DA  A7
	sbc    hl,de                               ; 12DB  ED 52
	jr     z,UpdateChannel_downkey             ; 12DD  28 08
	jr     nc,UpdateChannel_downkey            ; 12DF  30 06
	ld     (iy+$02),e                          ; 12E1  FD 73 02
	ld     (iy+$03),d                          ; 12E4  FD 72 03
UpdateChannel_downkey:
	set    6,(iy+$03)                          ; 12E7  FD CB 03 F6
UpdateChannel_writefreq:
	exx                                        ; 12EB  D9           write the new pitch (key state unchanged)
	ld     a,b                                 ; 12EC  78
	or     c                                   ; 12ED  B1
	call   nz,DAC_Poll                         ; 12EE  C4 4C 17
	exx                                        ; 12F1  D9
	ld     l,(iy+$02)                          ; 12F2  FD 6E 02
	ld     h,(iy+$03)                          ; 12F5  FD 66 03
	jp     WriteFreqKey                        ; 12F8  C3 C8 14
Slide:
	ld     l,(iy+$00)                          ; 12FB  FD 6E 00     pitch slide (cell effect nibble)
	ld     h,(iy+$01)                          ; 12FE  FD 66 01
	exx                                        ; 1301  D9
	ld     a,b                                 ; 1302  78
	or     c                                   ; 1303  B1
	call   nz,DAC_Poll                         ; 1304  C4 4C 17
	exx                                        ; 1307  D9
	ld     a,h                                 ; 1308  7C
	or     l                                   ; 1309  B5
	ret    z                                   ; 130A  C8
	add    hl,hl                               ; 130B  29           step*2
	ld     e,(iy+$02)                          ; 130C  FD 5E 02
	ld     d,(iy+$03)                          ; 130F  FD 56 03
	add    hl,de                               ; 1312  19
	push   hl                                  ; 1313  E5           wrap into $269..$4D0, adjusting the block
	ld     a,h                                 ; 1314  7C
	and    $07                                 ; 1315  E6 07
	ld     h,a                                 ; 1317  67
	ld     de,$0269                            ; 1318  11 69 02
	exx                                        ; 131B  D9
	ld     a,b                                 ; 131C  78
	or     c                                   ; 131D  B1
	call   nz,DAC_Poll                         ; 131E  C4 4C 17
	exx                                        ; 1321  D9
	sbc    hl,de                               ; 1322  ED 52
	pop    hl                                  ; 1324  E1
	jr     nc,Slide_chkhigh                    ; 1325  30 05
	add    hl,de                               ; 1327  19
	ld     a,h                                 ; 1328  7C
	sub    $08                                 ; 1329  D6 08
	ld     h,a                                 ; 132B  67
Slide_chkhigh:
	exx                                        ; 132C  D9
	ld     a,b                                 ; 132D  78
	or     c                                   ; 132E  B1
	call   nz,DAC_Poll                         ; 132F  C4 4C 17
	exx                                        ; 1332  D9
	push   hl                                  ; 1333  E5
	ld     a,h                                 ; 1334  7C
	and    $07                                 ; 1335  E6 07
	ld     h,a                                 ; 1337  67
	ld     de,$04D0                            ; 1338  11 D0 04
	sbc    hl,de                               ; 133B  ED 52
	pop    hl                                  ; 133D  E1
	jr     c,Slide_store                       ; 133E  38 10
	ld     de,$0269                            ; 1340  11 69 02
	sbc    hl,de                               ; 1343  ED 52
	exx                                        ; 1345  D9
	ld     a,b                                 ; 1346  78
	or     c                                   ; 1347  B1
	call   nz,DAC_Poll                         ; 1348  C4 4C 17
	exx                                        ; 134B  D9
	ld     a,h                                 ; 134C  7C
	add    a,$08                               ; 134D  C6 08
	ld     h,a                                 ; 134F  67
Slide_store:
	ld     a,h                                 ; 1350  7C           set key-on flag and write
	and    $3F                                 ; 1351  E6 3F
	set    6,h                                 ; 1353  CB F4
	ld     (iy+$02),l                          ; 1355  FD 75 02
	ld     (iy+$03),h                          ; 1358  FD 74 03
	call   WriteFreqKey                        ; 135B  CD C8 14
	ret                                        ; 135E  C9

; --------------------------------------------------------------------------
;  Row processing
; --------------------------------------------------------------------------
ApplyVoiceBank:
	push   af                                  ; 135F  F5           A = voice; add 32 when the upper voice bank is selected (cmd $7D bit 7)
	ld     a,(MB_JingleState)                  ; 1360  3A AD 0F
	or     a                                   ; 1363  B7
	jr     z,ApplyVoiceBank_music              ; 1364  28 15
	ld     a,c                                 ; 1366  79           FM5 during a jingle uses the jingle flag
	cp     $04                                 ; 1367  FE 04
	jr     nz,ApplyVoiceBank_music             ; 1369  20 10
	ld     (iy+$08),$FF                        ; 136B  FD 36 08 FF  force a reload of the music voice when the jingle ends
	ld     (iy+$09),$FF                        ; 136F  FD 36 09 FF
	ld     a,(MB_JingleBankHi)                 ; 1373  3A BB 0F
	or     a                                   ; 1376  B7
	jr     nz,ApplyVoiceBank_upper             ; 1377  20 0F
ApplyVoiceBank_lower:
	pop    af                                  ; 1379  F1
	ret                                        ; 137A  C9
ApplyVoiceBank_music:
	exx                                        ; 137B  D9
	ld     a,b                                 ; 137C  78
	or     c                                   ; 137D  B1
	call   nz,DAC_Poll                         ; 137E  C4 4C 17
	exx                                        ; 1381  D9
	ld     a,(MB_VoiceBankHi)                  ; 1382  3A BA 0F
	or     a                                   ; 1385  B7
	jr     z,ApplyVoiceBank_lower              ; 1386  28 F1
ApplyVoiceBank_upper:
	pop    af                                  ; 1388  F1
	set    5,a                                 ; 1389  CB EF
	ret                                        ; 138B  C9
NoteWordTmp:
	dw     $0000                               ; 138C  scratch: current cell

; DoNoteWord: one pattern cell, cell = hi:lo
;    hi bits 7-1 = N   (0 none, 1-$6C note, $6D-$74 drum sample, $75-$7F command)
;    hi bit 0 + lo bits 7-4 = I  (instrument 1-31, 0 = keep)
;    lo bits 3-0 = E   (pitch slide, sign/magnitude)
DoNoteWord:
	ld     (iy+$0D),$FF                        ; 138E  FD 36 0D FF  IX = cell, IY = channel, C = channel (0-5)
	ld     l,(ix+$00)                          ; 1392  DD 6E 00     HL = cell (H = hi byte, L = lo byte)
	ld     h,(ix+$01)                          ; 1395  DD 66 01
	exx                                        ; 1398  D9
	ld     a,b                                 ; 1399  78
	or     c                                   ; 139A  B1
	call   nz,DAC_Poll                         ; 139B  C4 4C 17
	exx                                        ; 139E  D9
	ld     a,h                                 ; 139F  7C           N = hi >> 1
	srl    a                                   ; 13A0  CB 3F
	and    $7F                                 ; 13A2  E6 7F
	cp     $6D                                 ; 13A4  FE 6D        $6D-$7F: sample or command
	jp     nc,DoCommandNote                    ; 13A6  D2 73 16
	ld     a,h                                 ; 13A9  7C
	or     l                                   ; 13AA  B5           empty cell
	ret    z                                   ; 13AB  C8
	ld     (NoteWordTmp),hl                    ; 13AC  22 8C 13
	srl    h                                   ; 13AF  CB 3C        HL >>= 1: L = instrument*8 + effect/2
	rr     l                                   ; 13B1  CB 1D
	exx                                        ; 13B3  D9
	ld     a,b                                 ; 13B4  78
	or     c                                   ; 13B5  B1
	call   nz,DAC_Poll                         ; 13B6  C4 4C 17
	exx                                        ; 13B9  D9
	ld     a,l                                 ; 13BA  7D
	srl    a                                   ; 13BB  CB 3F
	srl    a                                   ; 13BD  CB 3F
	srl    a                                   ; 13BF  CB 3F        I = (cell >> 4) & $1F
	and    $1F                                 ; 13C1  E6 1F
	jr     z,DoNoteWord_note                   ; 13C3  28 29
	dec    a                                   ; 13C5  3D           voice = I-1 (+32)
	call   ApplyVoiceBank                      ; 13C6  CD 5F 13
	cp     (iy+$08)                            ; 13C9  FD BE 08     same voice as before?
	ld     (iy+$08),a                          ; 13CC  FD 77 08
	jr     nz,DoNoteWord_loadvoice             ; 13CF  20 10
	ld     a,(iy+$06)                          ; 13D1  FD 7E 06     same voice and portamento active -> legato (no key re-trigger)
	or     a                                   ; 13D4  B7
	jr     z,DoNoteWord_samevoice              ; 13D5  28 04
	ld     (iy+$0D),$00                        ; 13D7  FD 36 0D 00
DoNoteWord_samevoice:
	ld     a,(iy+$0B)                          ; 13DB  FD 7E 0B
	or     a                                   ; 13DE  B7
	jr     z,DoNoteWord_note                   ; 13DF  28 0D
DoNoteWord_loadvoice:
	ld     (iy+$0B),$00                        ; 13E1  FD 36 0B 00  new voice: clear FMS override, load voice unless already loaded
	ld     a,(iy+$08)                          ; 13E5  FD 7E 08
	cp     (iy+$09)                            ; 13E8  FD BE 09
	call   nz,LoadChannelVoice                 ; 13EB  C4 71 0C
DoNoteWord_note:
	ld     hl,(NoteWordTmp)                    ; 13EE  2A 8C 13
	ld     a,h                                 ; 13F1  7C           note N
	srl    a                                   ; 13F2  CB 3F
	or     a                                   ; 13F4  B7
	jr     z,DoNoteWord_effect                 ; 13F5  28 6A        N = 0: no note, only effect
	sla    a                                   ; 13F7  CB 27
	ld     e,a                                 ; 13F9  5F
	ld     d,$00                               ; 13FA  16 00
	exx                                        ; 13FC  D9
	ld     a,b                                 ; 13FD  78
	or     c                                   ; 13FE  B1
	call   nz,DAC_Poll                         ; 13FF  C4 4C 17
	exx                                        ; 1402  D9
	ld     hl,NoteTable                        ; 1403  21 9F 17     target = NoteTable[N]
	add    hl,de                               ; 1406  19
	ld     a,(hl)                              ; 1407  7E
	inc    hl                                  ; 1408  23
	ld     h,(hl)                              ; 1409  66
	ld     l,a                                 ; 140A  6F
	ld     (iy+$04),l                          ; 140B  FD 75 04
	ld     (iy+$05),h                          ; 140E  FD 74 05
	exx                                        ; 1411  D9
	ld     a,b                                 ; 1412  78
	or     c                                   ; 1413  B1
	call   nz,DAC_Poll                         ; 1414  C4 4C 17
	exx                                        ; 1417  D9
	set    6,(iy+$03)                          ; 1418  FD CB 03 F6
	ld     a,(iy+$0D)                          ; 141C  FD 7E 0D     re-trigger: key off first (bit 6 clear)
	or     a                                   ; 141F  B7
	jr     z,DoNoteWord_noporta                ; 1420  28 04
	res    6,(iy+$03)                          ; 1422  FD CB 03 B6
DoNoteWord_noporta:
	ld     a,(iy+$06)                          ; 1426  FD 7E 06     no portamento: jump to the pitch now
	or     a                                   ; 1429  B7
	jr     nz,DoNoteWord_slideclr              ; 142A  20 06
	ld     (iy+$02),l                          ; 142C  FD 75 02
	ld     (iy+$03),h                          ; 142F  FD 74 03
DoNoteWord_slideclr:
	ld     hl,$0000                            ; 1432  21 00 00     clear slide
	ld     (iy+$00),l                          ; 1435  FD 75 00
	ld     (iy+$01),h                          ; 1438  FD 74 01
	exx                                        ; 143B  D9
	ld     a,b                                 ; 143C  78
	or     c                                   ; 143D  B1
	call   nz,DAC_Poll                         ; 143E  C4 4C 17
	exx                                        ; 1441  D9
	ld     a,c                                 ; 1442  79           FM note on FM6 (no jingle, no SFX sample): stop the music sample
	cp     $05                                 ; 1443  FE 05
	jr     nz,DoNoteWord_effect                ; 1445  20 1A
	ld     a,(MB_JingleState)                  ; 1447  3A AD 0F
	or     a                                   ; 144A  B7
	jr     nz,DoNoteWord_effect                ; 144B  20 14
	ld     a,(MB_SFXBusy)                      ; 144D  3A E4 0F
	or     a                                   ; 1450  B7
	jr     nz,DoNoteWord_effect                ; 1451  20 0E
	exx                                        ; 1453  D9
	ld     a,c                                 ; 1454  79
	or     b                                   ; 1455  B0
	jr     z,DoNoteWord_dacdone                ; 1456  28 08
	ld     a,$B6                               ; 1458  3E B6        restore FM6 pan register byte
	ld     (RegTable+$0173),a                  ; 145A  32 2F 0F
	ld     bc,$0001                            ; 145D  01 01 00     BC' = 1: the sample ends on the next poll
DoNoteWord_dacdone:
	exx                                        ; 1460  D9
DoNoteWord_effect:
	exx                                        ; 1461  D9
	ld     a,b                                 ; 1462  78
	or     c                                   ; 1463  B1
	call   nz,DAC_Poll                         ; 1464  C4 4C 17
	exx                                        ; 1467  D9
	ld     hl,(NoteWordTmp)                    ; 1468  2A 8C 13
	ld     a,l                                 ; 146B  7D           effect nibble E: slide step = +/-(E&7)*4, bit 3 = down
	and    $0F                                 ; 146C  E6 0F
	jr     z,DoNoteWord_key                    ; 146E  28 1A
	ld     h,a                                 ; 1470  67
	and    $07                                 ; 1471  E6 07
	bit    3,h                                 ; 1473  CB 5C
	jr     z,DoNoteWord_pos                    ; 1475  28 02
	cpl                                        ; 1477  2F
	inc    a                                   ; 1478  3C
DoNoteWord_pos:
	ld     l,a                                 ; 1479  6F
	ld     h,$00                               ; 147A  26 00
	bit    7,l                                 ; 147C  CB 7D
	jr     z,DoNoteWord_slidestore             ; 147E  28 02
	ld     h,$FF                               ; 1480  26 FF
DoNoteWord_slidestore:
	add    hl,hl                               ; 1482  29
	add    hl,hl                               ; 1483  29
	ld     (iy+$00),l                          ; 1484  FD 75 00
	ld     (iy+$01),h                          ; 1487  FD 74 01
DoNoteWord_key:
	exx                                        ; 148A  D9
	ld     a,b                                 ; 148B  78
	or     c                                   ; 148C  B1
	call   nz,DAC_Poll                         ; 148D  C4 4C 17
	exx                                        ; 1490  D9
	ld     l,(iy+$02)                          ; 1491  FD 6E 02     key on: bit 6 clear -> write key-off, then key-on
	ld     h,(iy+$03)                          ; 1494  FD 66 03
	bit    6,h                                 ; 1497  CB 74
	jr     nz,DoNoteWord_exit                  ; 1499  20 0F
	call   WriteFreqKey                        ; 149B  CD C8 14
	set    6,h                                 ; 149E  CB F4
	exx                                        ; 14A0  D9
	ld     a,b                                 ; 14A1  78
	or     c                                   ; 14A2  B1
	call   nz,DAC_Poll                         ; 14A3  C4 4C 17
	exx                                        ; 14A6  D9
	call   WriteFreqKey                        ; 14A7  CD C8 14
DoNoteWord_exit:
	set    6,(iy+$03)                          ; 14AA  FD CB 03 F6
	ret                                        ; 14AE  C9

; --------------------------------------------------------------------------
;  YM helpers
; --------------------------------------------------------------------------
YM_Init:
	ld     a,$22                               ; 14AF  3E 22        reg $22 = $0C (LFO on, 6.02 Hz), reg $27 = 0
	ld     (YM_A0),a                           ; 14B1  32 00 40
	rst    $10                                 ; 14B4  D7
	ld     a,$0C                               ; 14B5  3E 0C
	ld     (YM_D0),a                           ; 14B7  32 01 40
	rst    $10                                 ; 14BA  D7
	ld     a,$27                               ; 14BB  3E 27
	ld     (YM_A0),a                           ; 14BD  32 00 40
	rst    $10                                 ; 14C0  D7
	ld     a,$00                               ; 14C1  3E 00
	ld     (YM_D0),a                           ; 14C3  32 01 40
	rst    $10                                 ; 14C6  D7
	ret                                        ; 14C7  C9
WriteFreqKey:
	exx                                        ; 14C8  D9           HL = block/F-num word, bit 14 = key on; C = channel
	ld     a,b                                 ; 14C9  78
	or     c                                   ; 14CA  B1
	call   nz,DAC_Poll                         ; 14CB  C4 4C 17
	exx                                        ; 14CE  D9
	push   hl                                  ; 14CF  E5
	push   bc                                  ; 14D0  C5
	ld     e,$00                               ; 14D1  1E 00
	ld     a,c                                 ; 14D3  79
	cp     $03                                 ; 14D4  FE 03
	jr     c,WriteFreqKey_part                 ; 14D6  38 05
	sub    $03                                 ; 14D8  D6 03
	ld     c,a                                 ; 14DA  4F
	ld     e,$02                               ; 14DB  1E 02
WriteFreqKey_part:
	ld     d,$40                               ; 14DD  16 40
	ld     a,c                                 ; 14DF  79
	add    a,$A4                               ; 14E0  C6 A4        $A4+ch: block/F-num hi
	ld     (de),a                              ; 14E2  12
	rst    $10                                 ; 14E3  D7
	inc    de                                  ; 14E4  13
	ld     a,h                                 ; 14E5  7C
	and    $3F                                 ; 14E6  E6 3F
	ld     (de),a                              ; 14E8  12
	exx                                        ; 14E9  D9
	ld     a,b                                 ; 14EA  78
	or     c                                   ; 14EB  B1
	call   nz,DAC_Poll                         ; 14EC  C4 4C 17
	exx                                        ; 14EF  D9
	rst    $10                                 ; 14F0  D7
	dec    de                                  ; 14F1  1B
	ld     a,c                                 ; 14F2  79
	add    a,$A0                               ; 14F3  C6 A0        $A0+ch: F-num lo
	ld     (de),a                              ; 14F5  12
	rst    $10                                 ; 14F6  D7
	inc    de                                  ; 14F7  13
	ld     a,l                                 ; 14F8  7D
	ld     (de),a                              ; 14F9  12
	dec    de                                  ; 14FA  1B
	rst    $10                                 ; 14FB  D7
	exx                                        ; 14FC  D9
	ld     a,b                                 ; 14FD  78
	or     c                                   ; 14FE  B1
	call   nz,DAC_Poll                         ; 14FF  C4 4C 17
	exx                                        ; 1502  D9
	pop    bc                                  ; 1503  C1
	push   bc                                  ; 1504  C5
	ld     a,c                                 ; 1505  79           key code: 0,1,2,4,5,6
	and    $07                                 ; 1506  E6 07
	cp     $03                                 ; 1508  FE 03
	jr     c,WriteFreqKey_keycode              ; 150A  38 01
	inc    a                                   ; 150C  3C
WriteFreqKey_keycode:
	ld     c,$00                               ; 150D  0E 00
	bit    6,h                                 ; 150F  CB 74        bit 6 of H -> key on all operators
	jr     z,WriteFreqKey_keyoff               ; 1511  28 02
	ld     c,$F0                               ; 1513  0E F0
WriteFreqKey_keyoff:
	or     c                                   ; 1515  B1
	ex     af,af'                              ; 1516  08
	exx                                        ; 1517  D9
	ld     a,b                                 ; 1518  78
	or     c                                   ; 1519  B1
	call   nz,DAC_Poll                         ; 151A  C4 4C 17
	exx                                        ; 151D  D9
	ld     a,$28                               ; 151E  3E 28        reg $28
	ld     de,YM_A0                            ; 1520  11 00 40
	ld     (de),a                              ; 1523  12
	rst    $10                                 ; 1524  D7
	inc    e                                   ; 1525  1C
	ex     af,af'                              ; 1526  08
	ld     (de),a                              ; 1527  12
	rst    $10                                 ; 1528  D7
	exx                                        ; 1529  D9
	ld     a,b                                 ; 152A  78
	or     c                                   ; 152B  B1
	call   nz,DAC_Poll                         ; 152C  C4 4C 17
	exx                                        ; 152F  D9
	pop    bc                                  ; 1530  C1
	pop    hl                                  ; 1531  E1
	ret                                        ; 1532  C9

; --------------------------------------------------------------------------
;  Commands 4, 7, 2
; --------------------------------------------------------------------------
Cmd4_Silence:
	xor    a                                   ; 1533  AF           silence all channels (FM5 is skipped during a jingle)
	ld     (MB_MusicVol),a                     ; 1534  32 E6 0F
	ld     iy,ChanState                        ; 1537  FD 21 3C 0F
	ld     a,(MB_JingleState)                  ; 153B  3A AD 0F
	ld     (Cmd4_Silence_jflag+1),a            ; 153E  32 5F 15     SELF-MODIFY Cmd4_Silence_jflag ("ld a,0") with the jingle state
	exx                                        ; 1541  D9
	ld     a,(MB_SFXBusy)                      ; 1542  3A E4 0F     stop a music sample (not an SFX sample)
	or     a                                   ; 1545  B7
	jr     nz,Cmd4_Silence_chans               ; 1546  20 07
	ld     a,c                                 ; 1548  79
	or     b                                   ; 1549  B0
	jr     z,Cmd4_Silence_chans                ; 154A  28 03
	ld     bc,$0001                            ; 154C  01 01 00
Cmd4_Silence_chans:
	exx                                        ; 154F  D9
	ld     b,$06                               ; 1550  06 06
	ld     c,$00                               ; 1552  0E 00
Cmd4_Silence_loop:
	ld     (iy+$09),$FF                        ; 1554  FD 36 09 FF
	push   bc                                  ; 1558  C5
	ld     a,c                                 ; 1559  79
	cp     $04                                 ; 155A  FE 04
	jr     nz,Cmd4_Silence_silence             ; 155C  20 05
Cmd4_Silence_jflag:
	ld     a,$00                               ; 155E  3E 00
	or     a                                   ; 1560  B7
	jr     nz,Cmd4_Silence_clear               ; 1561  20 05
Cmd4_Silence_silence:
	ld     a,$80                               ; 1563  3E 80        silent voice
	call   LoadChannelVoice                    ; 1565  CD 71 0C
Cmd4_Silence_clear:
	xor    a                                   ; 1568  AF
	ld     (iy+$0C),a                          ; 1569  FD 77 0C
	ld     (iy+$0B),a                          ; 156C  FD 77 0B
	ld     (iy+$06),a                          ; 156F  FD 77 06
	ld     (iy+$09),$FF                        ; 1572  FD 36 09 FF
	ld     bc,$000E                            ; 1576  01 0E 00
	add    iy,bc                               ; 1579  FD 09
	pop    bc                                  ; 157B  C1
	inc    c                                   ; 157C  0C
	djnz   Cmd4_Silence_loop                   ; 157D  10 D5
	ret                                        ; 157F  C9
KeyCodeTable:
	db     $00,$01,$02,$04,$05,$06             ; 1580  unused copy of the key-code table
Cmd7_ReloadVoices:
	ld     iy,ChanState                        ; 1586  FD 21 3C 0F  reload the voice of every channel (end of pause)
	ld     b,$06                               ; 158A  06 06
	ld     c,$00                               ; 158C  0E 00
Cmd7_ReloadVoices_loop:
	ld     a,(iy+$08)                          ; 158E  FD 7E 08
	ld     (iy+$0B),$00                        ; 1591  FD 36 0B 00
	ld     (iy+$0C),$00                        ; 1595  FD 36 0C 00
	call   LoadChannelVoice                    ; 1599  CD 71 0C
	ld     (iy+$09),$FF                        ; 159C  FD 36 09 FF
	ld     de,$000E                            ; 15A0  11 0E 00
	add    iy,de                               ; 15A3  FD 19
	inc    c                                   ; 15A5  0C
	djnz   Cmd7_ReloadVoices_loop              ; 15A6  10 E6
	xor    a                                   ; 15A8  AF
	ld     (MB_Cmd),a                          ; 15A9  32 AC 0F
	jp     MainLoop                            ; 15AC  C3 F3 0F
Cmd2_Reset:
	ld     hl,$0000                            ; 15AF  21 00 00     stop: clear slides/porta, set "no key" pitch, invalidate voices (FM5 kept during a jingle)
	xor    a                                   ; 15B2  AF
	ld     (ChanState+$06),a                   ; 15B3  32 42 0F
	ld     (ChanState+$14),a                   ; 15B6  32 50 0F
	ld     (ChanState+$22),a                   ; 15B9  32 5E 0F
	ld     (ChanState+$30),a                   ; 15BC  32 6C 0F
	ld     (ChanState+$4C),a                   ; 15BF  32 88 0F
	ld     (ChanState+$0B),hl                  ; 15C2  22 47 0F
	ld     (ChanState+$19),hl                  ; 15C5  22 55 0F
	ld     (ChanState+$27),hl                  ; 15C8  22 63 0F
	ld     (ChanState+$35),hl                  ; 15CB  22 71 0F
	ld     (ChanState+$43),hl                  ; 15CE  22 7F 0F
	ld     (ChanState+$51),hl                  ; 15D1  22 8D 0F
	ld     (ChanState),hl                      ; 15D4  22 3C 0F
	ld     (ChanState+$0E),hl                  ; 15D7  22 4A 0F
	ld     (ChanState+$1C),hl                  ; 15DA  22 58 0F
	ld     (ChanState+$2A),hl                  ; 15DD  22 66 0F
	ld     (ChanState+$46),hl                  ; 15E0  22 82 0F
	ld     a,(MB_JingleState)                  ; 15E3  3A AD 0F
	or     a                                   ; 15E6  B7
	jr     nz,Cmd2_Reset_freq                  ; 15E7  20 03
	ld     (ChanState+$38),hl                  ; 15E9  22 74 0F
Cmd2_Reset_freq:
	ld     h,$20                               ; 15EC  26 20
	ld     (ChanState+$02),hl                  ; 15EE  22 3E 0F
	ld     (ChanState+$10),hl                  ; 15F1  22 4C 0F
	ld     (ChanState+$1E),hl                  ; 15F4  22 5A 0F
	ld     (ChanState+$2C),hl                  ; 15F7  22 68 0F
	ld     (ChanState+$48),hl                  ; 15FA  22 84 0F
	or     a                                   ; 15FD  B7
	jr     nz,Cmd2_Reset_voices                ; 15FE  20 03
	ld     (ChanState+$3A),hl                  ; 1600  22 76 0F
Cmd2_Reset_voices:
	ld     a,$FF                               ; 1603  3E FF
	ld     (ChanState+$08),a                   ; 1605  32 44 0F
	ld     (ChanState+$16),a                   ; 1608  32 52 0F
	ld     (ChanState+$24),a                   ; 160B  32 60 0F
	ld     (ChanState+$32),a                   ; 160E  32 6E 0F
	ld     (ChanState+$4E),a                   ; 1611  32 8A 0F
	ld     a,(MB_JingleState)                  ; 1614  3A AD 0F
	or     a                                   ; 1617  B7
	jp     nz,MainLoop                         ; 1618  C2 F3 0F
	ld     a,$FF                               ; 161B  3E FF
	ld     (ChanState+$40),a                   ; 161D  32 7C 0F
	ld     (ChanState+$09),a                   ; 1620  32 45 0F
	ld     (ChanState+$17),a                   ; 1623  32 53 0F
	ld     (ChanState+$25),a                   ; 1626  32 61 0F
	ld     (ChanState+$33),a                   ; 1629  32 6F 0F
	ld     (ChanState+$41),a                   ; 162C  32 7D 0F
	ld     (ChanState+$4F),a                   ; 162F  32 8B 0F
	xor    a                                   ; 1632  AF
	ld     (ChanState+$3E),a                   ; 1633  32 7A 0F
	jp     MainLoop                            ; 1636  C3 F3 0F

; --------------------------------------------------------------------------
;  Samples and command notes
; --------------------------------------------------------------------------
MusicSampleNote:
	cp     $6D                                 ; 1639  FE 6D        N $6D-$74: drum sample (N-$6D) on FM6 only, L = rate
	ret    c                                   ; 163B  D8
	sub    $6D                                 ; 163C  D6 6D
	ex     af,af'                              ; 163E  08
	ld     a,c                                 ; 163F  79
	cp     $05                                 ; 1640  FE 05
	ret    nz                                  ; 1642  C0
	ex     af,af'                              ; 1643  08
	push   bc                                  ; 1644  C5
	push   hl                                  ; 1645  E5
	push   de                                  ; 1646  D5
	ld     c,l                                 ; 1647  4D
	add    a,a                                 ; 1648  87
	add    a,a                                 ; 1649  87
	ld     l,a                                 ; 164A  6F
	ld     a,(MB_SFXBusy)                      ; 164B  3A E4 0F     SFX sample has priority
	or     a                                   ; 164E  B7
	jr     nz,MusicSampleNote_exit             ; 164F  20 1E
	ld     a,c                                 ; 1651  79
	ld     (MB_SmpRate),a                      ; 1652  32 BE 0F     rate
	ld     h,$00                               ; 1655  26 00
	ld     de,MB_SampleTable                   ; 1657  11 C4 0F     MB_SampleTable + 4*n
	add    hl,de                               ; 165A  19
	ld     b,(hl)                              ; 165B  46
	inc    hl                                  ; 165C  23
	ld     c,(hl)                              ; 165D  4E
	inc    hl                                  ; 165E  23
	ld     d,(hl)                              ; 165F  56
	inc    hl                                  ; 1660  23
	ld     e,(hl)                              ; 1661  5E
	set    7,b                                 ; 1662  CB F8        Z80 bank window $8000-$FFFF
	ld     (MB_SmpAddr),bc                     ; 1664  ED 43 BC 0F
	ld     (MB_SmpLen),de                      ; 1668  ED 53 C0 0F
	call   StartMusicSample                    ; 166C  CD FF 16
MusicSampleNote_exit:
	pop    de                                  ; 166F  D1
	pop    hl                                  ; 1670  E1
	pop    bc                                  ; 1671  C1
	ret                                        ; 1672  C9
DoCommandNote:
	push   af                                  ; 1673  F5           N >= $6D
	exx                                        ; 1674  D9
	ld     a,b                                 ; 1675  78
	or     c                                   ; 1676  B1
	call   nz,DAC_Poll                         ; 1677  C4 4C 17
	exx                                        ; 167A  D9
	pop    af                                  ; 167B  F1
	cp     $75                                 ; 167C  FE 75        $6D-$74: drum sample
	jr     c,MusicSampleNote                   ; 167E  38 B9
	cp     $7D                                 ; 1680  FE 7D        $7D: speed (68k) / voice bank (bit 7 of L)
	jr     nz,DoCommandNote_not7D              ; 1682  20 21
	ld     a,c                                 ; 1684  79
	cp     $04                                 ; 1685  FE 04
	jr     nz,DoCommandNote_music              ; 1687  20 06
	ld     a,(MB_JingleState)                  ; 1689  3A AD 0F
	or     a                                   ; 168C  B7
	jr     nz,DoCommandNote_jingle             ; 168D  20 0B
DoCommandNote_music:
	xor    a                                   ; 168F  AF
	bit    7,l                                 ; 1690  CB 7D
	jr     z,DoCommandNote_setbank             ; 1692  28 02
	ld     a,$FF                               ; 1694  3E FF
DoCommandNote_setbank:
	ld     (MB_VoiceBankHi),a                  ; 1696  32 BA 0F
	ret                                        ; 1699  C9
DoCommandNote_jingle:
	xor    a                                   ; 169A  AF
	bit    7,l                                 ; 169B  CB 7D
	jr     z,DoCommandNote_setjbank            ; 169D  28 02
	ld     a,$FF                               ; 169F  3E FF
DoCommandNote_setjbank:
	ld     (MB_JingleBankHi),a                 ; 16A1  32 BB 0F
	ret                                        ; 16A4  C9
DoCommandNote_not7D:
	cp     $7A                                 ; 16A5  FE 7A        $7A portamento speed, $7B pan, $7C FMS; $75-$79/$7E/$7F ignored
	jr     z,Cmd7A_Portamento                  ; 16A7  28 32
	cp     $7C                                 ; 16A9  FE 7C
	jr     z,Cmd7C_FMS                         ; 16AB  28 1D
	cp     $7B                                 ; 16AD  FE 7B
	ret    nz                                  ; 16AF  C0
	exx                                        ; 16B0  D9
	ld     a,b                                 ; 16B1  78
	or     c                                   ; 16B2  B1
	call   nz,DAC_Poll                         ; 16B3  C4 4C 17
	exx                                        ; 16B6  D9
	ld     a,l                                 ; 16B7  7D           $7B: pan = (L&3) << 6 : 1 = right, 2 = left, 3 = both, 0 = voice pan
	and    $03                                 ; 16B8  E6 03
	rrca                                       ; 16BA  0F
	rrca                                       ; 16BB  0F
	ld     (iy+$0C),a                          ; 16BC  FD 77 0C
	ld     a,(iy+$08)                          ; 16BF  FD 7E 08
	call   LoadChannelVoice                    ; 16C2  CD 71 0C     reload voice with the override
	ld     (iy+$09),$FF                        ; 16C5  FD 36 09 FF
	ret                                        ; 16C9  C9
Cmd7C_FMS:
	ld     a,l                                 ; 16CA  7D           $7C: FMS (vibrato depth) = L&7, 0 = voice value
	and    $07                                 ; 16CB  E6 07
	ld     (iy+$0B),a                          ; 16CD  FD 77 0B
	ld     a,(iy+$08)                          ; 16D0  FD 7E 08
	call   LoadChannelVoice                    ; 16D3  CD 71 0C
	ld     (iy+$09),$FF                        ; 16D6  FD 36 09 FF
	ret                                        ; 16DA  C9
Cmd7A_Portamento:
	ld     a,l                                 ; 16DB  7D           $7A: portamento speed (F-number units per tick), 0 = off
	ld     (iy+$06),a                          ; 16DC  FD 77 06
	ret                                        ; 16DF  C9
StartSFXSample:
	ld     a,$FF                               ; 16E0  3E FF        SFX sample requested by the 68k
	ld     (MB_SFXBusy),a                      ; 16E2  32 E4 0F     mark busy
	ld     a,(MB_SFXPan)                       ; 16E5  3A EA 0F     pan: MB_SFXPan or L+R
	or     a                                   ; 16E8  B7
	ld     a,$C0                               ; 16E9  3E C0
	jr     z,StartSFXSample_pan                ; 16EB  28 03
	ld     a,(MB_SFXPan)                       ; 16ED  3A EA 0F
StartSFXSample_pan:
	ld     l,a                                 ; 16F0  6F
	ld     a,$B6                               ; 16F1  3E B6
	ld     (YM_A1),a                           ; 16F3  32 02 40
	ld     a,l                                 ; 16F6  7D
	ld     (YM_D1),a                           ; 16F7  32 03 40
	ld     a,(MB_SFXBank)                      ; 16FA  3A EE 0F     bank of the SFX sample
	jr     StartSample                         ; 16FD  18 12
StartMusicSample:
	ld     a,$B6                               ; 16FF  3E B6        music drum: always centred
	ld     (YM_A1),a                           ; 1701  32 02 40
	ld     a,$C0                               ; 1704  3E C0
	ld     (YM_D1),a                           ; 1706  32 03 40
	ld     a,(MB_MusicVol)                     ; 1709  3A E6 0F     music volume non-zero (fading) -> drums are dropped
	or     a                                   ; 170C  B7
	ret    nz                                  ; 170D  C0
	ld     a,(MB_MusicBank)                    ; 170E  3A F0 0F     music sample bank
StartSample:
	call   SetBank                             ; 1711  CD 8F 17     select bank, DAC on
	ld     a,$2B                               ; 1714  3E 2B
	ld     (YM_A0),a                           ; 1716  32 00 40
	rst    $10                                 ; 1719  D7
	ld     a,$80                               ; 171A  3E 80
	ld     (YM_D0),a                           ; 171C  32 01 40
	ld     hl,(MB_SmpAddr)                     ; 171F  2A BC 0F     skip the first 8 bytes
	ld     de,$0008                            ; 1722  11 08 00
	add    hl,de                               ; 1725  19
	ld     de,(MB_SmpRate)                     ; 1726  ED 5B BE 0F  D = rate, E = phase
	ld     d,e                                 ; 172A  53
	ld     bc,(MB_SmpLen)                      ; 172B  ED 4B C0 0F  BC = length - 12 (whole sample if shorter)
	ld     a,c                                 ; 172F  79
	sub    $0C                                 ; 1730  D6 0C
	ld     c,a                                 ; 1732  4F
	ld     a,b                                 ; 1733  78
	sbc    a,$00                               ; 1734  DE 00
	ld     b,a                                 ; 1736  47
	jr     nc,StartSample_go                   ; 1737  30 07
	ld     bc,(MB_SmpLen)                      ; 1739  ED 4B C0 0F
	ld     hl,(MB_SmpAddr)                     ; 173D  2A BC 0F
StartSample_go:
	xor    a                                   ; 1740  AF
	ld     (MB_SmpTrigger),a                   ; 1741  32 C2 0F
	rst    $10                                 ; 1744  D7           BC'/DE'/HL' now hold the player state
	exx                                        ; 1745  D9
	ld     a,$28                               ; 1746  3E 28        redirect FM6 pan writes to $28 (dummy)
	ld     (RegTable+$0173),a                  ; 1748  32 2F 0F
	ret                                        ; 174B  C9

; --------------------------------------------------------------------------
;  DAC_Poll (alternate set): called whenever BC' != 0
; --------------------------------------------------------------------------
DAC_Poll:
	ld     a,d                                 ; 174C  7A           phase += rate; output one byte on carry. HL = ptr, BC = bytes left
	add    a,e                                 ; 174D  83
	ld     e,a                                 ; 174E  5F
	ret    nc                                  ; 174F  D0
	ld     a,$2A                               ; 1750  3E 2A        reg $2A DAC data
	ld     (YM_A0),a                           ; 1752  32 00 40
	ld     a,(hl)                              ; 1755  7E           signed -> unsigned
	add    a,$80                               ; 1756  C6 80
	ld     (YM_D0),a                           ; 1758  32 01 40
	inc    hl                                  ; 175B  23
	dec    bc                                  ; 175C  0B
	ld     a,b                                 ; 175D  78
	or     c                                   ; 175E  B1
	ret    nz                                  ; 175F  C0
	rst    $20                                 ; 1760  E7           end of sample
	ld     a,$B6                               ; 1761  3E B6        restore the FM6 pan byte in RegTable and select reg $B6
	ld     (RegTable+$0173),a                  ; 1763  32 2F 0F
	ld     (YM_A1),a                           ; 1766  32 02 40
	ld     a,(ChanState+$4E)                   ; 1769  3A 8A 0F     voice of FM6
	ld     de,VoiceBank                        ; 176C  11 00 04
	ld     h,$00                               ; 176F  26 00
	ld     l,a                                 ; 1771  6F
	add    hl,hl                               ; 1772  29
	add    hl,hl                               ; 1773  29
	add    hl,hl                               ; 1774  29
	add    hl,hl                               ; 1775  29
	add    hl,hl                               ; 1776  29
	add    hl,de                               ; 1777  19
	ld     de,$0019                            ; 1778  11 19 00     +$19 = pan/AMS/FMS byte
	add    hl,de                               ; 177B  19
	ld     a,(hl)                              ; 177C  7E
	ld     (YM_D1),a                           ; 177D  32 03 40
	ld     a,$2B                               ; 1780  3E 2B        DAC off
	ld     (YM_A0),a                           ; 1782  32 00 40
	rst    $20                                 ; 1785  E7
	xor    a                                   ; 1786  AF
	ld     (YM_D0),a                           ; 1787  32 01 40
	ld     (MB_SFXBusy),a                      ; 178A  32 E4 0F     SFX no longer busy
	rst    $20                                 ; 178D  E7
	ret                                        ; 178E  C9
SetBank:
	push   bc                                  ; 178F  C5           A = bank (A15-A22 of the 68k address); 9 serial writes to $6000, A23 = 0
	ld     b,$09                               ; 1790  06 09
	ld     c,a                                 ; 1792  4F
SetBank_bit:
	ld     a,c                                 ; 1793  79
	and    $01                                 ; 1794  E6 01
	ld     (BankReg),a                         ; 1796  32 00 60
	srl    c                                   ; 1799  CB 39
	djnz   SetBank_bit                         ; 179B  10 F6
	pop    bc                                  ; 179D  C1
	ret                                        ; 179E  C9

; --------------------------------------------------------------------------
;  Note table (word = block<<11 | F-number)
; --------------------------------------------------------------------------
NoteTable:
	dw     $0000,$0000,$0269,$028D,$02B4,$02DD,$0309,$0337,$0368,$039C,$03D3,$040D; 179F  98 words: N=0,1 unused, N=2..97 = block 0-7, 12 notes each (B-1 .. A#7, PAL-tuned)
	dw     $044B,$048C,$0A69,$0A8D,$0AB4,$0ADD,$0B09,$0B37,$0B68,$0B9C,$0BD3,$0C0D; 17B7
	dw     $0C4B,$0C8C,$1269,$128D,$12B4,$12DD,$1309,$1337,$1368,$139C,$13D3,$140D; 17CF
	dw     $144B,$148C,$1A69,$1A8D,$1AB4,$1ADD,$1B09,$1B37,$1B68,$1B9C,$1BD3,$1C0D; 17E7
	dw     $1C4B,$1C8C,$2269,$228D,$22B4,$22DD,$2309,$2337,$2368,$239C,$23D3,$240D; 17FF
	dw     $244B,$248C,$2A69,$2A8D,$2AB4,$2ADD,$2B09,$2B37,$2B68,$2B9C,$2BD3,$2C0D; 1817
	dw     $2C4B,$2C8C,$3269,$328D,$32B4,$32DD,$3309,$3337,$3368,$339C,$33D3,$340D; 182F
	dw     $344B,$348C,$3A69,$3A8D,$3AB4,$3ADD,$3B09,$3B37,$3B68,$3B9C,$3BD3,$3C0D; 1847
	dw     $3C4B,$3C8C                         ; 185F

; everything from here to $1FFF is junk that is uploaded with the driver ($1400 bytes)
DriverEnd:
	db     $00                                 ; 1863
