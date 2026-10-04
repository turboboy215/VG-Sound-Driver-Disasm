; Generated from the ROM by tools/zdis.py + z80_v2.py (labels/comments hand-written).
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
;  Revision 2 (Sensible Soccer (E) (M4)): ROM $06E4E2 -> Z80 $0C00
;  ($1400 bytes copied, $0A97 used).
;  Same row/tick protocol as revision 3 (Boogerman / Mickey Mania) with
;  volume, pan, FMS, portamento and ROM-bank selection, but the DAC is only
;  serviced from the main wait loop, so sample playback stalls while a
;  command is processed.  Voices are rewritten on every instrument change
;  (no CH_LOADED cache).
;
;  Channel state (IY, 14 bytes, ChanState + ch*14):
;    +00/01 slide step   +02/03 current pitch (bit 14 = key on)   +04/05 target pitch
;    +06 portamento speed   +08 voice   +0B FMS override   +0C pan override   +0D re-trigger flag
;  Alternate registers while a sample plays: HL' = pointer, BC' = bytes left,
;  D' = rate, E' = phase accumulator.
; ==========================================================================
Start:
	di                                         ; 0C00  F3           reset entry (68k writes DI / JP $0C00 at Z80 $0000 after uploading the driver)
	im     1                                   ; 0C01  ED 56
	ld     sp,$1FFF                            ; 0C03  31 FF 1F
	ld     hl,Init_RstVectors                  ; 0C06  21 38 0C     copy RST $08/$10 handlers to $0008-$001E
	ld     de,$0008                            ; 0C09  11 08 00
	ld     bc,$0017                            ; 0C0C  01 17 00
	ldir                                       ; 0C0F  ED B0
	ld     hl,Init_IntVector                   ; 0C11  21 48 0C     copy "ei / ret" interrupt stub to $0038 (IM 1, interrupts never enabled)
	ld     de,$0038                            ; 0C14  11 38 00
	ld     bc,$0008                            ; 0C17  01 08 00
	ldir                                       ; 0C1A  ED B0
	ld     hl,Init_Vec0000                     ; 0C1C  21 32 0C     copy "nop / jp $0C00 / dw MB_Cmd" to $0000-$0005
	ld     de,$0000                            ; 0C1F  11 00 00
	ld     bc,$0006                            ; 0C22  01 06 00
	ldir                                       ; 0C25  ED B0
	call   YM_Init                             ; 0C27  CD 46 13     LFO on (6.02 Hz), Timer/CH3 mode off
	exx                                        ; 0C2A  D9           BC' = 0: no sample playing
	ld     bc,$0000                            ; 0C2B  01 00 00
	exx                                        ; 0C2E  D9
	jp     MainLoop                            ; 0C2F  C3 9F 0F
Init_Vec0000:
	db     $00,$C3,$00,$0C,$58,$0F             ; 0C32  -> $0000: nop / jp Start / dw MB_Cmd ($0004 = mailbox pointer read by the 68k)
Init_RstVectors:
	db     $3A,$00,$40,$CB,$7F,$20,$F9,$C9     ; 0C38  -> $0008 RST 08h and $0010 RST 10h: wait while the YM is busy
	db     $3A,$00,$40,$CB,$7F,$20,$F9,$C9     ; 0C40
Init_IntVector:
	db     $FB,$C9                             ; 0C48  -> $0038: ei / ret

; --------------------------------------------------------------------------
;  LoadChannelVoice: A = voice, C = channel, IY = channel state
;  FM5 during a jingle: load with jingle volume, mark MB_JingleState=$FE,
;  then apply the jingle pan to register $B5.
; --------------------------------------------------------------------------
LoadChannelVoice:
	ex     af,af'                              ; 0C4A  08           (no CH_LOADED tracking in this revision: the voice is always rewritten)
	xor    a                                   ; 0C4B  AF
	ld     (LoadVoice_jflag+1),a               ; 0C4C  32 BC 0C     patch LoadVoice: "ld a,0" -> 0 = use music volume
	ld     a,c                                 ; 0C4F  79
	cp     $04                                 ; 0C50  FE 04
	jr     nz,LoadVoice                        ; 0C52  20 37
	ld     a,(MB_JingleState)                  ; 0C54  3A 59 0F
	or     a                                   ; 0C57  B7
	jr     z,LoadVoice                         ; 0C58  28 31
	ld     a,$01                               ; 0C5A  3E 01        patch LoadVoice: "ld a,1" -> use jingle volume
	ld     (LoadVoice_jflag+1),a               ; 0C5C  32 BC 0C
	call   LoadVoice                           ; 0C5F  CD 8B 0C
	push   ix                                  ; 0C62  DD E5
	ld     a,$FE                               ; 0C64  3E FE        jingle state $FE = jingle voice loaded on FM5
	ld     (MB_JingleState),a                  ; 0C66  32 59 0F
	ld     l,$C0                               ; 0C69  2E C0        default pan L+R
	ld     a,(MB_JinglePan)                    ; 0C6B  3A 98 0F     jingle pan from the 68k (0 = leave voice pan)
	or     a                                   ; 0C6E  B7
	jr     z,LoadChannelVoice_done             ; 0C6F  28 17
	and    $C0                                 ; 0C71  E6 C0
	ld     l,a                                 ; 0C73  6F
	ld     a,$B5                               ; 0C74  3E B5        part II reg $B5 = FM5 pan/AMS/FMS
	ld     (YM_A1),a                           ; 0C76  32 02 40
	rst    $08                                 ; 0C79  CF
	ld     ix,(CurVoicePtr)                    ; 0C7A  DD 2A 46 0D  keep AMS/FMS of the voice, replace pan bits
	ld     a,(ix+$19)                          ; 0C7E  DD 7E 19
	and    $3F                                 ; 0C81  E6 3F
	or     l                                   ; 0C83  B5
	ld     (YM_D1),a                           ; 0C84  32 03 40
	rst    $10                                 ; 0C87  D7
LoadChannelVoice_done:
	pop    ix                                  ; 0C88  DD E1
	ret                                        ; 0C8A  C9

; --------------------------------------------------------------------------
;  LoadVoice: write a 32-byte voice (26 registers) to channel C.
;  Voice layout: +00..03 DT/MUL, +04..07 TL, +08..0B KS/AR, +0C..0F AM/D1R,
;  +10..13 D2R, +14..17 D1L/RR (operator order 1,3,2,4), +18 FB/ALG,
;  +19 pan/AMS/FMS, +1A scratch (pan copy), +1B..1F unused.
; --------------------------------------------------------------------------
LoadVoice:
	ex     af,af'                              ; 0C8B  08           A = voice number (bit 7 set = silent voice), C = channel 0-5
	push   bc                                  ; 0C8C  C5
	ld     de,VoiceBank                        ; 0C8D  11 00 04
	ld     h,$00                               ; 0C90  26 00
	ld     l,a                                 ; 0C92  6F
	add    hl,hl                               ; 0C93  29
	add    hl,hl                               ; 0C94  29
	add    hl,hl                               ; 0C95  29
	add    hl,hl                               ; 0C96  29
	add    hl,hl                               ; 0C97  29
	add    hl,de                               ; 0C98  19           HL = $0400 + voice*32 (voice bank uploaded by the 68k)
	bit    7,a                                 ; 0C99  CB 7F
	jr     z,LoadVoice_havevoice               ; 0C9B  28 03
	ld     hl,SilentVoice                      ; 0C9D  21 48 0D     bit 7: silent voice (TL=$7F)
LoadVoice_havevoice:
	ld     (CurVoicePtr),hl                    ; 0CA0  22 46 0D
	ex     de,hl                               ; 0CA3  EB           DE = voice data
	ld     b,c                                 ; 0CA4  41           BC = channel*64
	ld     c,$00                               ; 0CA5  0E 00
	srl    b                                   ; 0CA7  CB 38
	rr     c                                   ; 0CA9  CB 19
	srl    b                                   ; 0CAB  CB 38
	rr     c                                   ; 0CAD  CB 19
	ld     hl,RegTable                         ; 0CAF  21 68 0D     HL = register list for this channel (32 x port,reg)
	add    hl,bc                               ; 0CB2  09
	ld     b,$40                               ; 0CB3  06 40
	ex     af,af'                              ; 0CB5  08
	ld     a,$04                               ; 0CB6  3E 04        4 x DT/MUL ($30-$3C)
	call   WriteRegList                        ; 0CB8  CD 33 0D
LoadVoice_jflag:
	ld     a,$00                               ; 0CBB  3E 00        SELF-MODIFIED by LoadChannelVoice: 1 = jingle channel
	or     a                                   ; 0CBD  B7
	jr     z,LoadVoice_musicvol                ; 0CBE  28 08
	ld     a,(MB_JingleVol)                    ; 0CC0  3A 94 0F     jingle volume
	or     a                                   ; 0CC3  B7
	jr     z,LoadVoice_novolume                ; 0CC4  28 2A
	jr     LoadVoice_withvolume                ; 0CC6  18 06
LoadVoice_musicvol:
	ld     a,(MB_MusicVol)                     ; 0CC8  3A 92 0F     music volume
	or     a                                   ; 0CCB  B7
	jr     z,LoadVoice_novolume                ; 0CCC  28 22        volume 0 -> write TLs straight from the voice
LoadVoice_withvolume:
	push   iy                                  ; 0CCE  FD E5
	push   bc                                  ; 0CD0  C5
	push   de                                  ; 0CD1  D5
	ld     (WriteTL_Carrier_vol+1),a           ; 0CD2  32 14 11     patch the volume into WriteTL_Carrier
	ld     iy,(CurVoicePtr)                    ; 0CD5  FD 2A 46 0D
	call   ApplyVolume                         ; 0CD9  CD 87 10     write the 4 TLs with carrier attenuation
	pop    de                                  ; 0CDC  D1
	pop    bc                                  ; 0CDD  C1
	pop    iy                                  ; 0CDE  FD E1
	inc    de                                  ; 0CE0  13           skip the 4 TL bytes / 4 TL register entries
	inc    de                                  ; 0CE1  13
	inc    de                                  ; 0CE2  13
	inc    de                                  ; 0CE3  13
	inc    hl                                  ; 0CE4  23
	inc    hl                                  ; 0CE5  23
	inc    hl                                  ; 0CE6  23
	inc    hl                                  ; 0CE7  23
	inc    hl                                  ; 0CE8  23
	inc    hl                                  ; 0CE9  23
	inc    hl                                  ; 0CEA  23
	inc    hl                                  ; 0CEB  23
	ld     a,$12                               ; 0CEC  3E 12        18 registers left ($50-$8C, $B0, $B4)
	jr     LoadVoice_write                     ; 0CEE  18 02
LoadVoice_novolume:
	ld     a,$16                               ; 0CF0  3E 16        22 registers ($40-$8C, $B0, $B4)
LoadVoice_write:
	call   WriteVoiceRegs                      ; 0CF2  CD F7 0C
	pop    bc                                  ; 0CF5  C1
	ret                                        ; 0CF6  C9
WriteVoiceRegs:
	cp     $01                                 ; 0CF7  FE 01        A = number of registers still to write; the last one ($B4) gets the overrides
	jr     nz,WriteVoiceRegs_notlast           ; 0CF9  20 26
	ex     af,af'                              ; 0CFB  08           last register = $B4 pan/AMS/FMS
	ld     a,(de)                              ; 0CFC  1A           copy voice byte $19 to scratch byte $1A and modify the copy
	inc    de                                  ; 0CFD  13
	ld     (de),a                              ; 0CFE  12
	ld     a,(iy+$0B)                          ; 0CFF  FD 7E 0B     FMS override (cmd $7C) or pan override (cmd $7B)?
	or     (iy+$0C)                            ; 0D02  FD B6 0C
	jr     z,WriteVoiceRegs_out                ; 0D05  28 1B
	ld     a,(iy+$0B)                          ; 0D07  FD 7E 0B
	ld     c,a                                 ; 0D0A  4F
	or     a                                   ; 0D0B  B7
	jr     z,WriteVoiceRegs_pan                ; 0D0C  28 05
	ld     a,(de)                              ; 0D0E  1A           FMS = override (LFO vibrato depth)
	and    $F8                                 ; 0D0F  E6 F8
	or     c                                   ; 0D11  B1
	ld     (de),a                              ; 0D12  12
WriteVoiceRegs_pan:
	ld     a,(iy+$0C)                          ; 0D13  FD 7E 0C
	ld     c,a                                 ; 0D16  4F
	or     a                                   ; 0D17  B7
	jr     z,WriteVoiceRegs_out                ; 0D18  28 08
	ld     a,(de)                              ; 0D1A  1A           pan bits = override
	and    $3F                                 ; 0D1B  E6 3F
	or     c                                   ; 0D1D  B1
	ld     (de),a                              ; 0D1E  12
	jr     WriteVoiceRegs_out                  ; 0D1F  18 01
WriteVoiceRegs_notlast:
	ex     af,af'                              ; 0D21  08
WriteVoiceRegs_out:
	ld     c,(hl)                              ; 0D22  4E           C = YM port low byte (0 = part I, 2 = part II), A = register
	inc    hl                                  ; 0D23  23
	ld     a,(hl)                              ; 0D24  7E
	inc    hl                                  ; 0D25  23
	ld     (bc),a                              ; 0D26  02           B = $40 -> YM address port
	rst    $08                                 ; 0D27  CF
	inc    c                                   ; 0D28  0C
	ld     a,(de)                              ; 0D29  1A
	ld     (bc),a                              ; 0D2A  02           data port
	rst    $10                                 ; 0D2B  D7
	inc    de                                  ; 0D2C  13
	ex     af,af'                              ; 0D2D  08
	dec    a                                   ; 0D2E  3D
	jr     nz,WriteVoiceRegs                   ; 0D2F  20 C6
	ex     af,af'                              ; 0D31  08
	ret                                        ; 0D32  C9
WriteRegList:
	ex     af,af'                              ; 0D33  08
	ld     c,(hl)                              ; 0D34  4E
	inc    hl                                  ; 0D35  23
	ld     a,(hl)                              ; 0D36  7E
	inc    hl                                  ; 0D37  23
	ld     (bc),a                              ; 0D38  02
	rst    $08                                 ; 0D39  CF
	inc    c                                   ; 0D3A  0C
	ld     a,(de)                              ; 0D3B  1A
	ld     (bc),a                              ; 0D3C  02
	rst    $10                                 ; 0D3D  D7
	inc    de                                  ; 0D3E  13
	ex     af,af'                              ; 0D3F  08
	dec    a                                   ; 0D40  3D
	jr     nz,WriteRegList                     ; 0D41  20 F0
	ex     af,af'                              ; 0D43  08
	ret                                        ; 0D44  C9
	db     $00                                 ; 0D45

; ---------------------------------------------------------------------- data
CurVoicePtr:
	dw     $0000                               ; 0D46  pointer to the voice last loaded by LoadVoice
SilentVoice:
	db     $00,$00,$00,$00,$7F,$7F,$7F,$7F     ; 0D48  "voice $80": all TL = $7F
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0D50
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0D58
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0D60
RegTable:
	db     $00,$30,$00,$34,$00,$38,$00,$3C,$00,$40,$00,$44,$00,$48,$00,$4C; 0D68  FM1: 32 x (port,reg): $30..$3C,$40..$4C,$50..$5C,$60..$6C,$70..$7C,$80..$8C,$B0,$B4,-,-,$90..$9C (only 26 used)
	db     $00,$50,$00,$54,$00,$58,$00,$5C,$00,$60,$00,$64,$00,$68,$00,$6C; 0D78
	db     $00,$70,$00,$74,$00,$78,$00,$7C,$00,$80,$00,$84,$00,$88,$00,$8C; 0D88
	db     $00,$B0,$00,$B4,$00,$00,$00,$00,$00,$90,$00,$94,$00,$98,$00,$9C; 0D98
	db     $00,$31,$00,$35,$00,$39,$00,$3D,$00,$41,$00,$45,$00,$49,$00,$4D; 0DA8  FM2
	db     $00,$51,$00,$55,$00,$59,$00,$5D,$00,$61,$00,$65,$00,$69,$00,$6D; 0DB8
	db     $00,$71,$00,$75,$00,$79,$00,$7D,$00,$81,$00,$85,$00,$89,$00,$8D; 0DC8
	db     $00,$B1,$00,$B5,$00,$00,$00,$00,$00,$91,$00,$95,$00,$99,$00,$9D; 0DD8
	db     $00,$32,$00,$36,$00,$3A,$00,$3E,$00,$42,$00,$46,$00,$4A,$00,$4E; 0DE8  FM3
	db     $00,$52,$00,$56,$00,$5A,$00,$5E,$00,$62,$00,$66,$00,$6A,$00,$6E; 0DF8
	db     $00,$72,$00,$76,$00,$7A,$00,$7E,$00,$82,$00,$86,$00,$8A,$00,$8E; 0E08
	db     $00,$B2,$00,$B6,$00,$00,$00,$00,$00,$92,$00,$96,$00,$9A,$00,$9E; 0E18
	db     $02,$30,$02,$34,$02,$38,$02,$3C,$02,$40,$02,$44,$02,$48,$02,$4C; 0E28  FM4 (part II)
	db     $02,$50,$02,$54,$02,$58,$02,$5C,$02,$60,$02,$64,$02,$68,$02,$6C; 0E38
	db     $02,$70,$02,$74,$02,$78,$02,$7C,$02,$80,$02,$84,$02,$88,$02,$8C; 0E48
	db     $02,$B0,$02,$B4,$00,$00,$00,$00,$02,$90,$02,$94,$02,$98,$02,$9C; 0E58
	db     $02,$31,$02,$35,$02,$39,$02,$3D,$02,$41,$02,$45,$02,$49,$02,$4D; 0E68  FM5
	db     $02,$51,$02,$55,$02,$59,$02,$5D,$02,$61,$02,$65,$02,$69,$02,$6D; 0E78
	db     $02,$71,$02,$75,$02,$79,$02,$7D,$02,$81,$02,$85,$02,$89,$02,$8D; 0E88
	db     $02,$B1,$02,$B5,$00,$00,$00,$00,$02,$91,$02,$95,$02,$99,$02,$9D; 0E98
	db     $02,$32,$02,$36,$02,$3A,$02,$3E,$02,$42,$02,$46,$02,$4A,$02,$4E; 0EA8  FM6: the $B6 byte at $0F2F is patched to $28 while a sample plays
	db     $02,$52,$02,$56,$02,$5A,$02,$5E,$02,$62,$02,$66,$02,$6A,$02,$6E; 0EB8
	db     $02,$72,$02,$76,$02,$7A,$02,$7E,$02,$82,$02,$86,$02,$8A,$02,$8E; 0EC8
	db     $02,$B2,$02,$B6,$00,$00,$00,$00,$02,$92,$02,$96,$02,$9A,$02,$9E; 0ED8

; ---------------------------------------------------------------------- RAM
;  ChanState: 6 x 14 bytes (FM1..FM6)
ChanState:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0EE8  6 x 14 bytes, see header
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0EF6
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F04
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F12
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F20
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F2E
Unused_0F3C:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F3C
Cmd3_ChanState:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F4A  scratch channel state used by command 3

; --------------------------------------------------------------------------
;  Mailbox (68k writes with the bus held; its address is read from $0004)
; --------------------------------------------------------------------------
MB_Cmd:
	db     $00                                 ; 0F58  68k command: 1 tick, 2 reset, 3 load voice, 4 silence, 7 reload voices, other (10) = new row
MB_JingleState:
	db     $00                                 ; 0F59  0 = no jingle; $FF = jingle playing on FM5 (68k); $FE = jingle voice loaded (Z80)
MB_Notes:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0F5A  6 pattern cells (lo,hi) for FM1-FM6; FM5 holds the jingle cell while a jingle plays
MB_VoiceBankHi:
	db     $00                                 ; 0F66  cmd $7D bit 7 for music: voices 32-63
MB_JingleBankHi:
	db     $00                                 ; 0F67  cmd $7D bit 7 for the jingle
MB_SmpAddr:
	dw     $1693                               ; 0F68  sample start ($8000 | offset in bank)
MB_SmpRate:
	db     $58                                 ; 0F6A  sample rate step (phase increment per poll, /256)
MB_SmpPhase:
	db     $00                                 ; 0F6B  initial phase (never written by the 68k)
MB_SmpLen:
	dw     $09A2                               ; 0F6C  sample length (bytes)
MB_SmpTrigger:
	db     $00                                 ; 0F6E  non-zero = start an SFX sample (68k)
MB_Pad_17:
	db     $00                                 ; 0F6F
MB_SampleTable:
	db     $00,$00,$00,$00                     ; 0F70  8 x (addr.hi, addr.lo, len.hi, len.lo), big-endian copy of the module sample table
	db     $00,$00,$00,$00                     ; 0F74
	db     $00,$00,$00,$00                     ; 0F78
	db     $00,$00,$00,$00                     ; 0F7C
	db     $00,$00,$00,$00                     ; 0F80
	db     $00,$00,$00,$00                     ; 0F84
	db     $00,$00,$00,$00                     ; 0F88
	db     $00,$00,$00,$00                     ; 0F8C
MB_SFXBusy:
	db     $00                                 ; 0F90  $FF while an SFX sample plays (music drums are ignored)
MB_Pad_39:
	db     $00                                 ; 0F91
MB_MusicVol:
	db     $00                                 ; 0F92  music attenuation added to carrier TLs (0 = full volume)
MB_Pad_3B:
	db     $00                                 ; 0F93
MB_JingleVol:
	db     $00                                 ; 0F94  jingle attenuation
MB_Pad_3D:
	db     $00                                 ; 0F95
MB_SFXPan:
	db     $00                                 ; 0F96  SFX sample pan (0 = centre)
MB_Pad_3F:
	db     $00                                 ; 0F97
MB_JinglePan:
	db     $00                                 ; 0F98  jingle pan (0 = voice pan)
MB_Pad_41:
	db     $00                                 ; 0F99
MB_SFXBank:
	db     $00                                 ; 0F9A  ROM bank (addr>>15) of the SFX sample
MB_Pad_43:
	db     $00                                 ; 0F9B
MB_MusicBank:
	db     $00                                 ; 0F9C  ROM bank of the music sample table
MB_Pad_45:
	db     $00                                 ; 0F9D
LastJingleState:
	db     $00                                 ; 0F9E  jingle state seen at the previous row (Z80 private)

; --------------------------------------------------------------------------
;  Main loop
; --------------------------------------------------------------------------
MainLoop:
	ld     a,(MB_MusicVol)                     ; 0F9F  3A 92 0F     re-apply music volume after every command (used for fades)
	or     a                                   ; 0FA2  B7
	call   nz,RefreshMusicTL                   ; 0FA3  C4 47 10
	ld     a,(MB_JingleState)                  ; 0FA6  3A 59 0F     jingle voice loaded?
	cp     $FE                                 ; 0FA9  FE FE
	call   z,RefreshJingleTL                   ; 0FAB  CC 32 10     -> keep FM5 at jingle volume
	xor    a                                   ; 0FAE  AF           command done: clear MB_Cmd (the 68k waits for 0 before writing the next one)
	ld     (MB_Cmd),a                          ; 0FAF  32 58 0F
WaitCommand:
	ld     a,(MB_SmpTrigger)                   ; 0FB2  3A 6E 0F     wait for a command; the DAC is only serviced in this loop
	or     a                                   ; 0FB5  B7
	call   nz,StartSFXSample                   ; 0FB6  C4 12 15     68k requested an SFX sample
	exx                                        ; 0FB9  D9
	ld     a,b                                 ; 0FBA  78
	or     c                                   ; 0FBB  B1
	call   nz,DAC_Poll                         ; 0FBC  C4 74 15
	exx                                        ; 0FBF  D9
	ld     a,(MB_Cmd)                          ; 0FC0  3A 58 0F
	or     a                                   ; 0FC3  B7
	jr     z,WaitCommand                       ; 0FC4  28 EC
	cp     $01                                 ; 0FC6  FE 01        1: tick only
	jr     z,WaitCommand_tick                  ; 0FC8  28 62
	cp     $02                                 ; 0FCA  FE 02        2: reset
	jp     z,Cmd2_Reset                        ; 0FCC  CA 0D 14
	cp     $03                                 ; 0FCF  FE 03
	jr     nz,WaitCommand_not3                 ; 0FD1  20 10
	ld     a,(MB_Notes+1)                      ; 0FD3  3A 5B 0F     3: load voice MB_Notes[0] on channel MB_Notes[1]
	ld     c,a                                 ; 0FD6  4F
	ld     a,(MB_Notes)                        ; 0FD7  3A 5A 0F
	ld     iy,Cmd3_ChanState                   ; 0FDA  FD 21 4A 0F
	call   LoadChannelVoice                    ; 0FDE  CD 4A 0C
	jr     MainLoop                            ; 0FE1  18 BC
WaitCommand_not3:
	cp     $04                                 ; 0FE3  FE 04        4: silence
	jr     nz,WaitCommand_not4                 ; 0FE5  20 05
	call   Cmd4_Silence                        ; 0FE7  CD A7 13
	jr     MainLoop                            ; 0FEA  18 B3
WaitCommand_not4:
	cp     $07                                 ; 0FEC  FE 07        7: reload voices (resume)
	jp     z,Cmd7_ReloadVoices                 ; 0FEE  CA EC 13
	ld     a,(MB_JingleState)                  ; 0FF1  3A 59 0F     otherwise: new row
	and    $FE                                 ; 0FF4  E6 FE
	ld     c,a                                 ; 0FF6  4F
	ld     a,(LastJingleState)                 ; 0FF7  3A 9E 0F     jingle started or stopped since the last row?
	cp     c                                   ; 0FFA  B9
	jr     z,WaitCommand_rowloop_init          ; 0FFB  28 12
	ld     a,c                                 ; 0FFD  79
	ld     (LastJingleState),a                 ; 0FFE  32 9E 0F
	ld     iy,ChanState+$38                    ; 1001  FD 21 20 0F  FM5: clear portamento, FMS and pan overrides
	xor    a                                   ; 1005  AF
	ld     (iy+$06),a                          ; 1006  FD 77 06
	ld     (iy+$0B),a                          ; 1009  FD 77 0B
	ld     (iy+$0C),a                          ; 100C  FD 77 0C
WaitCommand_rowloop_init:
	ld     b,$06                               ; 100F  06 06
	ld     c,$00                               ; 1011  0E 00
	ld     ix,MB_Notes                         ; 1013  DD 21 5A 0F  IX = note cells, IY = channel state
	ld     iy,ChanState                        ; 1017  FD 21 E8 0E
WaitCommand_rowloop:
	push   bc                                  ; 101B  C5
	call   DoNoteWord                          ; 101C  CD 65 12
	inc    ix                                  ; 101F  DD 23
	inc    ix                                  ; 1021  DD 23
	ld     de,$000E                            ; 1023  11 0E 00
	add    iy,de                               ; 1026  FD 19
	pop    bc                                  ; 1028  C1
	inc    c                                   ; 1029  0C
	djnz   WaitCommand_rowloop                 ; 102A  10 EF
WaitCommand_tick:
	call   UpdateAllChannels                   ; 102C  CD 2E 11     apply slides / portamento
	jp     MainLoop                            ; 102F  C3 9F 0F

; --------------------------------------------------------------------------
;  Volume (TL) handling
; --------------------------------------------------------------------------
RefreshJingleTL:
	ld     a,(MB_JingleVol)                    ; 1032  3A 94 0F     keep the jingle voice on FM5 at jingle volume
	ld     (WriteTL_Carrier_vol+1),a           ; 1035  32 14 11
	ld     ix,ChanState+$38                    ; 1038  DD 21 20 0F
	ld     hl,RegTable+$0108                   ; 103C  21 70 0E     TL register entries of FM5
	ld     a,(ix+$08)                          ; 103F  DD 7E 08
	or     a                                   ; 1042  B7
	call   p,ApplyVolumeVoice                  ; 1043  F4 76 10
	ret                                        ; 1046  C9
RefreshMusicTL:
	ld     b,$06                               ; 1047  06 06
	ld     a,(MB_MusicVol)                     ; 1049  3A 92 0F     rewrite carrier TLs of every channel with MB_MusicVol
	ld     (WriteTL_Carrier_vol+1),a           ; 104C  32 14 11
	ld     ix,ChanState                        ; 104F  DD 21 E8 0E
	ld     hl,RegTable+$08                     ; 1053  21 70 0D     TL entries of FM1
RefreshMusicTL_loop:
	push   bc                                  ; 1056  C5
	ld     a,b                                 ; 1057  78
	cp     $02                                 ; 1058  FE 02        FM5 (B=2) is skipped while a jingle owns it
	jr     nz,RefreshMusicTL_do                ; 105A  20 06
	ld     a,(MB_JingleState)                  ; 105C  3A 59 0F
	or     a                                   ; 105F  B7
	jr     nz,RefreshMusicTL_next              ; 1060  20 07
RefreshMusicTL_do:
	ld     a,(ix+$08)                          ; 1062  DD 7E 08     voice loaded?
	or     a                                   ; 1065  B7
	call   p,ApplyVolumeVoice                  ; 1066  F4 76 10
RefreshMusicTL_next:
	ld     bc,$000E                            ; 1069  01 0E 00
	add    ix,bc                               ; 106C  DD 09
	ld     bc,$0040                            ; 106E  01 40 00
	add    hl,bc                               ; 1071  09
	pop    bc                                  ; 1072  C1
	djnz   RefreshMusicTL_loop                 ; 1073  10 E1
	ret                                        ; 1075  C9
ApplyVolumeVoice:
	push   hl                                  ; 1076  E5           IY = $0400 + A*32
	ld     l,a                                 ; 1077  6F
	ld     h,$00                               ; 1078  26 00
	add    hl,hl                               ; 107A  29
	add    hl,hl                               ; 107B  29
	add    hl,hl                               ; 107C  29
	add    hl,hl                               ; 107D  29
	add    hl,hl                               ; 107E  29
	ld     de,VoiceBank                        ; 107F  11 00 04
	add    hl,de                               ; 1082  19
	push   hl                                  ; 1083  E5
	pop    iy                                  ; 1084  FD E1
	pop    hl                                  ; 1086  E1
ApplyVolume:
	push   hl                                  ; 1087  E5           IY = voice, HL = TL register entries; carriers get +volume
	ld     a,(iy+$18)                          ; 1088  FD 7E 18     FB/ALG
	and    $07                                 ; 108B  E6 07
	or     a                                   ; 108D  B7
	jr     z,ApplyVolume_alg0123               ; 108E  28 2C
	dec    a                                   ; 1090  3D
	jr     z,ApplyVolume_alg0123               ; 1091  28 29
	dec    a                                   ; 1093  3D
	jr     z,ApplyVolume_alg0123               ; 1094  28 26
	dec    a                                   ; 1096  3D
	jr     z,ApplyVolume_alg0123               ; 1097  28 23
	dec    a                                   ; 1099  3D
	jr     z,ApplyVolume_alg4                  ; 109A  28 3A
	dec    a                                   ; 109C  3D
	jr     z,ApplyVolume_alg56                 ; 109D  28 51
	dec    a                                   ; 109F  3D
	jr     z,ApplyVolume_alg56                 ; 10A0  28 4E
	ld     a,(iy+$04)                          ; 10A2  FD 7E 04     ALG 7: all four operators are carriers
	call   WriteTL_Carrier                     ; 10A5  CD 0A 11
	ld     a,(iy+$05)                          ; 10A8  FD 7E 05
	call   WriteTL_Carrier                     ; 10AB  CD 0A 11
	ld     a,(iy+$06)                          ; 10AE  FD 7E 06
	call   WriteTL_Carrier                     ; 10B1  CD 0A 11
	ld     a,(iy+$07)                          ; 10B4  FD 7E 07
	call   WriteTL_Carrier                     ; 10B7  CD 0A 11
	pop    hl                                  ; 10BA  E1
	ret                                        ; 10BB  C9
ApplyVolume_alg0123:
	ld     a,(iy+$04)                          ; 10BC  FD 7E 04     ALG 0-3: only op4 is a carrier
	call   WriteTL_Mod                         ; 10BF  CD 21 11
	ld     a,(iy+$05)                          ; 10C2  FD 7E 05
	call   WriteTL_Mod                         ; 10C5  CD 21 11
	ld     a,(iy+$06)                          ; 10C8  FD 7E 06
	call   WriteTL_Mod                         ; 10CB  CD 21 11
	ld     a,(iy+$07)                          ; 10CE  FD 7E 07
	call   WriteTL_Carrier                     ; 10D1  CD 0A 11
	pop    hl                                  ; 10D4  E1
	ret                                        ; 10D5  C9
ApplyVolume_alg4:
	ld     a,(iy+$04)                          ; 10D6  FD 7E 04     ALG 4: op2 and op4
	call   WriteTL_Mod                         ; 10D9  CD 21 11
	ld     a,(iy+$05)                          ; 10DC  FD 7E 05
	call   WriteTL_Mod                         ; 10DF  CD 21 11
	ld     a,(iy+$06)                          ; 10E2  FD 7E 06
	call   WriteTL_Carrier                     ; 10E5  CD 0A 11
	ld     a,(iy+$07)                          ; 10E8  FD 7E 07
	call   WriteTL_Carrier                     ; 10EB  CD 0A 11
	pop    hl                                  ; 10EE  E1
	ret                                        ; 10EF  C9
ApplyVolume_alg56:
	ld     a,(iy+$04)                          ; 10F0  FD 7E 04     ALG 5/6: op2, op3, op4
	call   WriteTL_Mod                         ; 10F3  CD 21 11
	ld     a,(iy+$05)                          ; 10F6  FD 7E 05
	call   WriteTL_Carrier                     ; 10F9  CD 0A 11
	ld     a,(iy+$06)                          ; 10FC  FD 7E 06
	call   WriteTL_Carrier                     ; 10FF  CD 0A 11
	ld     a,(iy+$07)                          ; 1102  FD 7E 07
	call   WriteTL_Carrier                     ; 1105  CD 0A 11
	pop    hl                                  ; 1108  E1
	ret                                        ; 1109  C9
WriteTL_Carrier:
	ld     b,$40                               ; 110A  06 40
	ld     c,(hl)                              ; 110C  4E
	inc    hl                                  ; 110D  23
	push   af                                  ; 110E  F5
	ld     a,(hl)                              ; 110F  7E
	inc    hl                                  ; 1110  23
	ld     (bc),a                              ; 1111  02
	rst    $08                                 ; 1112  CF
WriteTL_Carrier_vol:
	ld     a,$00                               ; 1113  3E 00        SELF-MODIFIED: volume
	ld     e,a                                 ; 1115  5F
	pop    af                                  ; 1116  F1
	add    a,e                                 ; 1117  83
	bit    7,a                                 ; 1118  CB 7F        clamp to $7F
	jr     z,WriteTL_Carrier_write             ; 111A  28 02
	ld     a,$7F                               ; 111C  3E 7F
WriteTL_Carrier_write:
	inc    c                                   ; 111E  0C
	ld     (bc),a                              ; 111F  02
	ret                                        ; 1120  C9
WriteTL_Mod:
	ld     b,$40                               ; 1121  06 40
	ld     c,(hl)                              ; 1123  4E
	inc    hl                                  ; 1124  23
	push   af                                  ; 1125  F5
	ld     a,(hl)                              ; 1126  7E
	inc    hl                                  ; 1127  23
	ld     (bc),a                              ; 1128  02
	rst    $08                                 ; 1129  CF
	pop    af                                  ; 112A  F1
	inc    c                                   ; 112B  0C
	ld     (bc),a                              ; 112C  02
	ret                                        ; 112D  C9

; --------------------------------------------------------------------------
;  Per-tick pitch update: portamento ($7A) or slide (effect nibble)
; --------------------------------------------------------------------------
UpdateAllChannels:
	ld     b,$06                               ; 112E  06 06        per-tick update of all 6 channels
	ld     c,$00                               ; 1130  0E 00
	ld     iy,ChanState                        ; 1132  FD 21 E8 0E
UpdateAllChannels_loop:
	call   UpdateChannel                       ; 1136  CD 51 11
	ld     de,$000E                            ; 1139  11 0E 00
	add    iy,de                               ; 113C  FD 19
	inc    c                                   ; 113E  0C
	djnz   UpdateAllChannels_loop              ; 113F  10 F5
	ret                                        ; 1141  C9
Porta_Start:
	ld     l,(iy+$04)                          ; 1142  FD 6E 04     first portamento step from silence: jump straight to the target
	ld     h,(iy+$05)                          ; 1145  FD 66 05
	ld     (iy+$02),l                          ; 1148  FD 75 02
	ld     (iy+$03),h                          ; 114B  FD 74 03
	jp     UpdateChannel_writefreq             ; 114E  C3 F0 11
UpdateChannel:
	ld     a,(iy+$06)                          ; 1151  FD 7E 06     IY = channel: portamento if CH_PORTA != 0, else slide
	or     a                                   ; 1154  B7
	jp     z,Slide                             ; 1155  CA F9 11
	ld     l,(iy+$04)                          ; 1158  FD 6E 04     HL = target
	ld     h,(iy+$05)                          ; 115B  FD 66 05
	ld     e,(iy+$02)                          ; 115E  FD 5E 02     DE = current
	ld     d,(iy+$03)                          ; 1161  FD 56 03
	ld     a,d                                 ; 1164  7A           strip the key-on flag
	and    $3F                                 ; 1165  E6 3F
	ld     d,a                                 ; 1167  57
	ld     a,d                                 ; 1168  7A
	or     e                                   ; 1169  B3
	jr     z,Porta_Start                       ; 116A  28 D6
	push   hl                                  ; 116C  E5
	and    a                                   ; 116D  A7
	sbc    hl,de                               ; 116E  ED 52        compare target with current
	pop    hl                                  ; 1170  E1
	jr     z,UpdateChannel_reached             ; 1171  28 04
	jr     nc,UpdateChannel_up                 ; 1173  30 03
	jr     UpdateChannel_down                  ; 1175  18 3D
UpdateChannel_reached:
	ret                                        ; 1177  C9
UpdateChannel_up:
	ex     de,hl                               ; 1178  EB           current += speed
	ld     d,$00                               ; 1179  16 00
	ld     e,(iy+$06)                          ; 117B  FD 5E 06
	add    hl,de                               ; 117E  19
	push   hl                                  ; 117F  E5           F-number above $4D0 -> next block, F-num - $269
	ld     a,h                                 ; 1180  7C
	and    $07                                 ; 1181  E6 07
	ld     h,a                                 ; 1183  67
	ld     de,$04D0                            ; 1184  11 D0 04
	and    a                                   ; 1187  A7
	sbc    hl,de                               ; 1188  ED 52
	pop    hl                                  ; 118A  E1
	jr     c,UpdateChannel_upstore             ; 118B  38 0A
	ld     de,$0269                            ; 118D  11 69 02
	and    a                                   ; 1190  A7
	sbc    hl,de                               ; 1191  ED 52
	ld     a,h                                 ; 1193  7C
	add    a,$08                               ; 1194  C6 08
	ld     h,a                                 ; 1196  67
UpdateChannel_upstore:
	ld     (iy+$02),l                          ; 1197  FD 75 02     clamp at target
	ld     (iy+$03),h                          ; 119A  FD 74 03
	ld     e,(iy+$04)                          ; 119D  FD 5E 04
	ld     d,(iy+$05)                          ; 11A0  FD 56 05
	and    a                                   ; 11A3  A7
	sbc    hl,de                               ; 11A4  ED 52
	jr     c,UpdateChannel_upkey               ; 11A6  38 06
	ld     (iy+$02),e                          ; 11A8  FD 73 02
	ld     (iy+$03),d                          ; 11AB  FD 72 03
UpdateChannel_upkey:
	set    6,(iy+$03)                          ; 11AE  FD CB 03 F6  key-on flag
	jr     UpdateChannel_writefreq             ; 11B2  18 3C
UpdateChannel_down:
	ex     de,hl                               ; 11B4  EB           current -= speed
	ld     d,$00                               ; 11B5  16 00
	ld     e,(iy+$06)                          ; 11B7  FD 5E 06
	and    a                                   ; 11BA  A7
	sbc    hl,de                               ; 11BB  ED 52
	push   hl                                  ; 11BD  E5
	ld     a,h                                 ; 11BE  7C
	and    $07                                 ; 11BF  E6 07
	ld     h,a                                 ; 11C1  67
	ld     de,$0269                            ; 11C2  11 69 02     F-number below $269 -> previous block, F-num + $269
	and    a                                   ; 11C5  A7
	sbc    hl,de                               ; 11C6  ED 52
	pop    hl                                  ; 11C8  E1
	jr     nc,UpdateChannel_downstore          ; 11C9  30 08
	ld     de,$0269                            ; 11CB  11 69 02
	add    hl,de                               ; 11CE  19
	ld     a,h                                 ; 11CF  7C
	sub    $08                                 ; 11D0  D6 08
	ld     h,a                                 ; 11D2  67
UpdateChannel_downstore:
	ld     (iy+$02),l                          ; 11D3  FD 75 02
	ld     (iy+$03),h                          ; 11D6  FD 74 03
	ld     e,(iy+$04)                          ; 11D9  FD 5E 04
	ld     d,(iy+$05)                          ; 11DC  FD 56 05
	and    a                                   ; 11DF  A7
	sbc    hl,de                               ; 11E0  ED 52
	jr     z,UpdateChannel_downkey             ; 11E2  28 08
	jr     nc,UpdateChannel_downkey            ; 11E4  30 06
	ld     (iy+$02),e                          ; 11E6  FD 73 02
	ld     (iy+$03),d                          ; 11E9  FD 72 03
UpdateChannel_downkey:
	set    6,(iy+$03)                          ; 11EC  FD CB 03 F6
UpdateChannel_writefreq:
	ld     l,(iy+$02)                          ; 11F0  FD 6E 02
	ld     h,(iy+$03)                          ; 11F3  FD 66 03
	jp     WriteFreqKey                        ; 11F6  C3 5F 13
Slide:
	ld     l,(iy+$00)                          ; 11F9  FD 6E 00     pitch slide (cell effect nibble)
	ld     h,(iy+$01)                          ; 11FC  FD 66 01
	ld     a,h                                 ; 11FF  7C
	or     l                                   ; 1200  B5
	ret    z                                   ; 1201  C8
	add    hl,hl                               ; 1202  29           step*2
	ld     e,(iy+$02)                          ; 1203  FD 5E 02
	ld     d,(iy+$03)                          ; 1206  FD 56 03
	add    hl,de                               ; 1209  19
	push   hl                                  ; 120A  E5           wrap into $269..$4D0, adjusting the block
	ld     a,h                                 ; 120B  7C
	and    $07                                 ; 120C  E6 07
	ld     h,a                                 ; 120E  67
	ld     de,$0269                            ; 120F  11 69 02
	sbc    hl,de                               ; 1212  ED 52
	pop    hl                                  ; 1214  E1
	jr     nc,Slide_chkhigh                    ; 1215  30 05
	add    hl,de                               ; 1217  19
	ld     a,h                                 ; 1218  7C
	sub    $08                                 ; 1219  D6 08
	ld     h,a                                 ; 121B  67
Slide_chkhigh:
	push   hl                                  ; 121C  E5
	ld     a,h                                 ; 121D  7C
	and    $07                                 ; 121E  E6 07
	ld     h,a                                 ; 1220  67
	ld     de,$04D0                            ; 1221  11 D0 04
	sbc    hl,de                               ; 1224  ED 52
	pop    hl                                  ; 1226  E1
	jr     c,Slide_store                       ; 1227  38 09
	ld     de,$0269                            ; 1229  11 69 02
	sbc    hl,de                               ; 122C  ED 52
	ld     a,h                                 ; 122E  7C
	add    a,$08                               ; 122F  C6 08
	ld     h,a                                 ; 1231  67
Slide_store:
	ld     a,h                                 ; 1232  7C           set key-on flag and write
	and    $3F                                 ; 1233  E6 3F
	set    6,h                                 ; 1235  CB F4
	ld     (iy+$02),l                          ; 1237  FD 75 02
	ld     (iy+$03),h                          ; 123A  FD 74 03
	call   WriteFreqKey                        ; 123D  CD 5F 13
	ret                                        ; 1240  C9

; --------------------------------------------------------------------------
;  Row processing
; --------------------------------------------------------------------------
ApplyVoiceBank:
	push   af                                  ; 1241  F5           A = voice; add 32 when the upper voice bank is selected (cmd $7D bit 7)
	ld     a,(MB_JingleState)                  ; 1242  3A 59 0F
	or     a                                   ; 1245  B7
	jr     z,ApplyVoiceBank_music              ; 1246  28 11
	ld     a,c                                 ; 1248  79           FM5 during a jingle uses the jingle flag
	cp     $04                                 ; 1249  FE 04
	jr     nz,ApplyVoiceBank_music             ; 124B  20 0C
	ld     (iy+$08),$FF                        ; 124D  FD 36 08 FF  force a reload of the music voice when the jingle ends
	ld     a,(MB_JingleBankHi)                 ; 1251  3A 67 0F
	or     a                                   ; 1254  B7
	jr     nz,ApplyVoiceBank_upper             ; 1255  20 08
ApplyVoiceBank_lower:
	pop    af                                  ; 1257  F1
	ret                                        ; 1258  C9
ApplyVoiceBank_music:
	ld     a,(MB_VoiceBankHi)                  ; 1259  3A 66 0F
	or     a                                   ; 125C  B7
	jr     z,ApplyVoiceBank_lower              ; 125D  28 F8
ApplyVoiceBank_upper:
	pop    af                                  ; 125F  F1
	set    5,a                                 ; 1260  CB EF
	ret                                        ; 1262  C9
NoteWordTmp:
	dw     $0000                               ; 1263

; DoNoteWord: one pattern cell, cell = hi:lo
;    hi bits 7-1 = N   (0 none, 1-$6C note, $6D-$74 drum sample, $75-$7F command)
;    hi bit 0 + lo bits 7-4 = I  (instrument 1-31, 0 = keep)
;    lo bits 3-0 = E   (pitch slide, sign/magnitude)
DoNoteWord:
	ld     (iy+$0D),$FF                        ; 1265  FD 36 0D FF  IX = cell, IY = channel, C = channel (0-5)
	ld     l,(ix+$00)                          ; 1269  DD 6E 00     HL = cell (H = hi byte, L = lo byte)
	ld     h,(ix+$01)                          ; 126C  DD 66 01
	ld     a,h                                 ; 126F  7C           N = hi >> 1
	srl    a                                   ; 1270  CB 3F
	and    $7F                                 ; 1272  E6 7F
	cp     $6D                                 ; 1274  FE 6D        $6D-$7F: sample or command
	jp     nc,DoCommandNote                    ; 1276  D2 BF 14
	ld     a,h                                 ; 1279  7C
	or     l                                   ; 127A  B5           empty cell
	ret    z                                   ; 127B  C8
	ld     (NoteWordTmp),hl                    ; 127C  22 63 12
	srl    h                                   ; 127F  CB 3C        HL >>= 1: L = instrument*8 + effect/2
	rr     l                                   ; 1281  CB 1D
	ld     a,l                                 ; 1283  7D
	srl    a                                   ; 1284  CB 3F
	srl    a                                   ; 1286  CB 3F
	srl    a                                   ; 1288  CB 3F        I = (cell >> 4) & $1F
	and    $1F                                 ; 128A  E6 1F
	jr     z,DoNoteWord_note                   ; 128C  28 26
	dec    a                                   ; 128E  3D           voice = I-1 (+32)
	call   ApplyVoiceBank                      ; 128F  CD 41 12
	cp     (iy+$08)                            ; 1292  FD BE 08     same voice as before?
	ld     (iy+$08),a                          ; 1295  FD 77 08
	jr     nz,DoNoteWord_loadvoice             ; 1298  20 10
	ld     a,(iy+$06)                          ; 129A  FD 7E 06     same voice and portamento active -> legato (no key re-trigger)
	or     a                                   ; 129D  B7
	jr     z,DoNoteWord_samevoice              ; 129E  28 04
	ld     (iy+$0D),$00                        ; 12A0  FD 36 0D 00
DoNoteWord_samevoice:
	ld     a,(iy+$0B)                          ; 12A4  FD 7E 0B
	or     a                                   ; 12A7  B7
	jr     z,DoNoteWord_note                   ; 12A8  28 0A
DoNoteWord_loadvoice:
	ld     (iy+$0B),$00                        ; 12AA  FD 36 0B 00  new voice: clear the FMS override and load it
	ld     a,(iy+$08)                          ; 12AE  FD 7E 08
	call   LoadChannelVoice                    ; 12B1  CD 4A 0C
DoNoteWord_note:
	ld     hl,(NoteWordTmp)                    ; 12B4  2A 63 12
	ld     a,h                                 ; 12B7  7C           note N
	srl    a                                   ; 12B8  CB 3F
	or     a                                   ; 12BA  B7
	jr     z,DoNoteWord_effect                 ; 12BB  28 50        N = 0: no note, only effect
	sla    a                                   ; 12BD  CB 27
	ld     e,a                                 ; 12BF  5F
	ld     d,$00                               ; 12C0  16 00
	ld     hl,NoteTable                        ; 12C2  21 CF 15     target = NoteTable[N]
	add    hl,de                               ; 12C5  19
	ld     a,(hl)                              ; 12C6  7E
	inc    hl                                  ; 12C7  23
	ld     h,(hl)                              ; 12C8  66
	ld     l,a                                 ; 12C9  6F
	ld     (iy+$04),l                          ; 12CA  FD 75 04
	ld     (iy+$05),h                          ; 12CD  FD 74 05
	set    6,(iy+$03)                          ; 12D0  FD CB 03 F6
	ld     a,(iy+$0D)                          ; 12D4  FD 7E 0D     re-trigger: key off first (bit 6 clear)
	or     a                                   ; 12D7  B7
	jr     z,DoNoteWord_noporta                ; 12D8  28 04
	res    6,(iy+$03)                          ; 12DA  FD CB 03 B6
DoNoteWord_noporta:
	ld     a,(iy+$06)                          ; 12DE  FD 7E 06     no portamento: jump to the pitch now
	or     a                                   ; 12E1  B7
	jr     nz,DoNoteWord_slideclr              ; 12E2  20 06
	ld     (iy+$02),l                          ; 12E4  FD 75 02
	ld     (iy+$03),h                          ; 12E7  FD 74 03
DoNoteWord_slideclr:
	ld     hl,$0000                            ; 12EA  21 00 00     clear slide
	ld     (iy+$00),l                          ; 12ED  FD 75 00
	ld     (iy+$01),h                          ; 12F0  FD 74 01
	ld     a,c                                 ; 12F3  79           FM note on FM6 (no jingle, no SFX sample): stop the music sample
	cp     $05                                 ; 12F4  FE 05
	jr     nz,DoNoteWord_effect                ; 12F6  20 15
	ld     a,(MB_JingleState)                  ; 12F8  3A 59 0F
	or     a                                   ; 12FB  B7
	jr     nz,DoNoteWord_effect                ; 12FC  20 0F
	ld     a,(MB_SFXBusy)                      ; 12FE  3A 90 0F
	or     a                                   ; 1301  B7
	jr     nz,DoNoteWord_effect                ; 1302  20 09
	exx                                        ; 1304  D9
	ld     a,c                                 ; 1305  79
	or     b                                   ; 1306  B0
	jr     z,DoNoteWord_dacdone                ; 1307  28 03
	ld     bc,$0001                            ; 1309  01 01 00     BC' = 1: the sample ends on the next poll
DoNoteWord_dacdone:
	exx                                        ; 130C  D9
DoNoteWord_effect:
	ld     hl,(NoteWordTmp)                    ; 130D  2A 63 12
	ld     a,l                                 ; 1310  7D           effect nibble E: slide step = +/-(E&7)*4, bit 3 = down
	and    $0F                                 ; 1311  E6 0F
	jr     z,DoNoteWord_key                    ; 1313  28 1A
	ld     h,a                                 ; 1315  67
	and    $07                                 ; 1316  E6 07
	bit    3,h                                 ; 1318  CB 5C
	jr     z,DoNoteWord_pos                    ; 131A  28 02
	cpl                                        ; 131C  2F
	inc    a                                   ; 131D  3C
DoNoteWord_pos:
	ld     l,a                                 ; 131E  6F
	ld     h,$00                               ; 131F  26 00
	bit    7,l                                 ; 1321  CB 7D
	jr     z,DoNoteWord_slidestore             ; 1323  28 02
	ld     h,$FF                               ; 1325  26 FF
DoNoteWord_slidestore:
	add    hl,hl                               ; 1327  29
	add    hl,hl                               ; 1328  29
	ld     (iy+$00),l                          ; 1329  FD 75 00
	ld     (iy+$01),h                          ; 132C  FD 74 01
DoNoteWord_key:
	ld     l,(iy+$02)                          ; 132F  FD 6E 02     key on: bit 6 clear -> write key-off, then key-on
	ld     h,(iy+$03)                          ; 1332  FD 66 03
	bit    6,h                                 ; 1335  CB 74
	jr     nz,DoNoteWord_exit                  ; 1337  20 08
	call   WriteFreqKey                        ; 1339  CD 5F 13
	set    6,h                                 ; 133C  CB F4
	call   WriteFreqKey                        ; 133E  CD 5F 13
DoNoteWord_exit:
	set    6,(iy+$03)                          ; 1341  FD CB 03 F6
	ret                                        ; 1345  C9

; --------------------------------------------------------------------------
;  YM helpers
; --------------------------------------------------------------------------
YM_Init:
	ld     a,$22                               ; 1346  3E 22        reg $22 = $0C (LFO on, 6.02 Hz), reg $27 = 0
	ld     (YM_A0),a                           ; 1348  32 00 40
	rst    $08                                 ; 134B  CF
	ld     a,$0C                               ; 134C  3E 0C
	ld     (YM_D0),a                           ; 134E  32 01 40
	rst    $10                                 ; 1351  D7
	ld     a,$27                               ; 1352  3E 27
	ld     (YM_A0),a                           ; 1354  32 00 40
	rst    $08                                 ; 1357  CF
	ld     a,$00                               ; 1358  3E 00
	ld     (YM_D0),a                           ; 135A  32 01 40
	rst    $10                                 ; 135D  D7
	ret                                        ; 135E  C9
WriteFreqKey:
	push   hl                                  ; 135F  E5
	push   bc                                  ; 1360  C5
	ld     e,$00                               ; 1361  1E 00
	ld     a,c                                 ; 1363  79
	cp     $03                                 ; 1364  FE 03
	jr     c,WriteFreqKey_part                 ; 1366  38 05
	sub    $03                                 ; 1368  D6 03
	ld     c,a                                 ; 136A  4F
	ld     e,$02                               ; 136B  1E 02
WriteFreqKey_part:
	ld     d,$40                               ; 136D  16 40
	ld     a,c                                 ; 136F  79
	add    a,$A4                               ; 1370  C6 A4        $A4+ch: block/F-num hi
	ld     (de),a                              ; 1372  12
	rst    $08                                 ; 1373  CF
	inc    de                                  ; 1374  13
	ld     a,h                                 ; 1375  7C
	and    $3F                                 ; 1376  E6 3F
	ld     (de),a                              ; 1378  12
	rst    $10                                 ; 1379  D7
	dec    de                                  ; 137A  1B
	ld     a,c                                 ; 137B  79
	add    a,$A0                               ; 137C  C6 A0        $A0+ch: F-num lo
	ld     (de),a                              ; 137E  12
	rst    $08                                 ; 137F  CF
	inc    de                                  ; 1380  13
	ld     a,l                                 ; 1381  7D
	ld     (de),a                              ; 1382  12
	dec    de                                  ; 1383  1B
	rst    $10                                 ; 1384  D7
	pop    bc                                  ; 1385  C1
	push   bc                                  ; 1386  C5
	ld     a,c                                 ; 1387  79           key code: 0,1,2,4,5,6
	and    $07                                 ; 1388  E6 07
	cp     $03                                 ; 138A  FE 03
	jr     c,WriteFreqKey_keycode              ; 138C  38 01
	inc    a                                   ; 138E  3C
WriteFreqKey_keycode:
	ld     c,$00                               ; 138F  0E 00
	bit    6,h                                 ; 1391  CB 74        bit 6 of H -> key on all operators
	jr     z,WriteFreqKey_keyoff               ; 1393  28 02
	ld     c,$F0                               ; 1395  0E F0
WriteFreqKey_keyoff:
	or     c                                   ; 1397  B1
	ex     af,af'                              ; 1398  08
	ld     a,$28                               ; 1399  3E 28        reg $28
	ld     de,YM_A0                            ; 139B  11 00 40
	ld     (de),a                              ; 139E  12
	rst    $08                                 ; 139F  CF
	inc    e                                   ; 13A0  1C
	ex     af,af'                              ; 13A1  08
	ld     (de),a                              ; 13A2  12
	rst    $10                                 ; 13A3  D7
	pop    bc                                  ; 13A4  C1
	pop    hl                                  ; 13A5  E1
	ret                                        ; 13A6  C9

; --------------------------------------------------------------------------
;  Commands 4, 7, 2
; --------------------------------------------------------------------------
Cmd4_Silence:
	xor    a                                   ; 13A7  AF           silence all channels (FM5 is skipped during a jingle)
	ld     (MB_MusicVol),a                     ; 13A8  32 92 0F
	ld     iy,ChanState                        ; 13AB  FD 21 E8 0E
	ld     a,(MB_JingleState)                  ; 13AF  3A 59 0F
	ld     (Cmd4_Silence_jflag+1),a            ; 13B2  32 C9 13     SELF-MODIFY Cmd4_Silence_jflag ("ld a,0") with the jingle state
	exx                                        ; 13B5  D9           stop the playing sample (music or SFX)
	ld     a,c                                 ; 13B6  79
	or     b                                   ; 13B7  B0
	jr     z,Cmd4_Silence_chans                ; 13B8  28 03
	ld     bc,$0001                            ; 13BA  01 01 00
Cmd4_Silence_chans:
	exx                                        ; 13BD  D9
	ld     b,$06                               ; 13BE  06 06
	ld     c,$00                               ; 13C0  0E 00
Cmd4_Silence_loop:
	push   bc                                  ; 13C2  C5
	ld     a,c                                 ; 13C3  79
	cp     $04                                 ; 13C4  FE 04
	jr     nz,Cmd4_Silence_silence             ; 13C6  20 05
Cmd4_Silence_jflag:
	ld     a,$00                               ; 13C8  3E 00
	or     a                                   ; 13CA  B7
	jr     nz,Cmd4_Silence_clear               ; 13CB  20 05
Cmd4_Silence_silence:
	ld     a,$80                               ; 13CD  3E 80        silent voice
	call   LoadChannelVoice                    ; 13CF  CD 4A 0C
Cmd4_Silence_clear:
	xor    a                                   ; 13D2  AF
	ld     (iy+$0C),a                          ; 13D3  FD 77 0C
	ld     (iy+$0B),a                          ; 13D6  FD 77 0B
	ld     (iy+$06),a                          ; 13D9  FD 77 06
	ld     bc,$000E                            ; 13DC  01 0E 00
	add    iy,bc                               ; 13DF  FD 09
	pop    bc                                  ; 13E1  C1
	inc    c                                   ; 13E2  0C
	djnz   Cmd4_Silence_loop                   ; 13E3  10 DD
	ret                                        ; 13E5  C9
KeyCodeTable:
	db     $00,$01,$02,$04,$05,$06             ; 13E6
Cmd7_ReloadVoices:
	ld     iy,ChanState                        ; 13EC  FD 21 E8 0E  reload the voice of every channel (end of pause)
	ld     b,$06                               ; 13F0  06 06
	ld     c,$00                               ; 13F2  0E 00
Cmd7_ReloadVoices_loop:
	ld     a,(iy+$08)                          ; 13F4  FD 7E 08
	ld     (iy+$0B),$00                        ; 13F7  FD 36 0B 00
	ld     (iy+$0C),$00                        ; 13FB  FD 36 0C 00
	call   LoadChannelVoice                    ; 13FF  CD 4A 0C
	ld     de,$000E                            ; 1402  11 0E 00
	add    iy,de                               ; 1405  FD 19
	inc    c                                   ; 1407  0C
	djnz   Cmd7_ReloadVoices_loop              ; 1408  10 EA
	jp     MainLoop                            ; 140A  C3 9F 0F
Cmd2_Reset:
	ld     hl,$0000                            ; 140D  21 00 00     stop: clear slides/porta, set "no key" pitch, invalidate voices (FM5 kept during a jingle)
	xor    a                                   ; 1410  AF
	ld     (ChanState+$06),a                   ; 1411  32 EE 0E
	ld     (ChanState+$14),a                   ; 1414  32 FC 0E
	ld     (ChanState+$22),a                   ; 1417  32 0A 0F
	ld     (ChanState+$30),a                   ; 141A  32 18 0F
	ld     (ChanState+$4C),a                   ; 141D  32 34 0F
	ld     (ChanState+$0B),hl                  ; 1420  22 F3 0E
	ld     (ChanState+$19),hl                  ; 1423  22 01 0F
	ld     (ChanState+$27),hl                  ; 1426  22 0F 0F
	ld     (ChanState+$35),hl                  ; 1429  22 1D 0F
	ld     (ChanState+$43),hl                  ; 142C  22 2B 0F
	ld     (ChanState+$51),hl                  ; 142F  22 39 0F
	ld     (ChanState),hl                      ; 1432  22 E8 0E
	ld     (ChanState+$0E),hl                  ; 1435  22 F6 0E
	ld     (ChanState+$1C),hl                  ; 1438  22 04 0F
	ld     (ChanState+$2A),hl                  ; 143B  22 12 0F
	ld     (ChanState+$46),hl                  ; 143E  22 2E 0F
	ld     a,(MB_JingleState)                  ; 1441  3A 59 0F
	or     a                                   ; 1444  B7
	jr     nz,Cmd2_Reset_freq                  ; 1445  20 03
	ld     (ChanState+$38),hl                  ; 1447  22 20 0F
Cmd2_Reset_freq:
	ld     h,$20                               ; 144A  26 20
	ld     (ChanState+$02),hl                  ; 144C  22 EA 0E
	ld     (ChanState+$10),hl                  ; 144F  22 F8 0E
	ld     (ChanState+$1E),hl                  ; 1452  22 06 0F
	ld     (ChanState+$2C),hl                  ; 1455  22 14 0F
	ld     (ChanState+$48),hl                  ; 1458  22 30 0F
	or     a                                   ; 145B  B7
	jr     nz,Cmd2_Reset_voices                ; 145C  20 03
	ld     (ChanState+$3A),hl                  ; 145E  22 22 0F
Cmd2_Reset_voices:
	ld     a,$FF                               ; 1461  3E FF
	ld     (ChanState+$08),a                   ; 1463  32 F0 0E
	ld     (ChanState+$16),a                   ; 1466  32 FE 0E
	ld     (ChanState+$24),a                   ; 1469  32 0C 0F
	ld     (ChanState+$32),a                   ; 146C  32 1A 0F
	ld     (ChanState+$4E),a                   ; 146F  32 36 0F
	ld     a,(MB_JingleState)                  ; 1472  3A 59 0F
	or     a                                   ; 1475  B7
	jp     nz,MainLoop                         ; 1476  C2 9F 0F
	ld     a,$FF                               ; 1479  3E FF
	ld     (ChanState+$40),a                   ; 147B  32 28 0F
	xor    a                                   ; 147E  AF
	ld     (ChanState+$3E),a                   ; 147F  32 26 0F
	jp     MainLoop                            ; 1482  C3 9F 0F

; --------------------------------------------------------------------------
;  Samples and command notes
; --------------------------------------------------------------------------
MusicSampleNote:
	cp     $6D                                 ; 1485  FE 6D        N $6D-$74: drum sample (N-$6D) on FM6 only, L = rate
	ret    c                                   ; 1487  D8
	sub    $6D                                 ; 1488  D6 6D
	ex     af,af'                              ; 148A  08
	ld     a,c                                 ; 148B  79
	cp     $05                                 ; 148C  FE 05
	ret    nz                                  ; 148E  C0
	ex     af,af'                              ; 148F  08
	push   bc                                  ; 1490  C5
	push   hl                                  ; 1491  E5
	push   de                                  ; 1492  D5
	ld     c,l                                 ; 1493  4D
	add    a,a                                 ; 1494  87
	add    a,a                                 ; 1495  87
	ld     l,a                                 ; 1496  6F
	ld     a,(MB_SFXBusy)                      ; 1497  3A 90 0F     SFX sample has priority
	or     a                                   ; 149A  B7
	jr     nz,MusicSampleNote_exit             ; 149B  20 1E
	ld     a,c                                 ; 149D  79
	ld     (MB_SmpRate),a                      ; 149E  32 6A 0F     rate
	ld     h,$00                               ; 14A1  26 00
	ld     de,MB_SampleTable                   ; 14A3  11 70 0F     MB_SampleTable + 4*n
	add    hl,de                               ; 14A6  19
	ld     b,(hl)                              ; 14A7  46
	inc    hl                                  ; 14A8  23
	ld     c,(hl)                              ; 14A9  4E
	inc    hl                                  ; 14AA  23
	ld     d,(hl)                              ; 14AB  56
	inc    hl                                  ; 14AC  23
	ld     e,(hl)                              ; 14AD  5E
	set    7,b                                 ; 14AE  CB F8        Z80 bank window $8000-$FFFF
	ld     (MB_SmpAddr),bc                     ; 14B0  ED 43 68 0F
	ld     (MB_SmpLen),de                      ; 14B4  ED 53 6C 0F
	call   StartMusicSample                    ; 14B8  CD 2D 15
MusicSampleNote_exit:
	pop    de                                  ; 14BB  D1
	pop    hl                                  ; 14BC  E1
	pop    bc                                  ; 14BD  C1
	ret                                        ; 14BE  C9
DoCommandNote:
	cp     $75                                 ; 14BF  FE 75        $6D-$74: drum sample
	jr     c,MusicSampleNote                   ; 14C1  38 C2
	cp     $7D                                 ; 14C3  FE 7D        $7D: speed (68k) / voice bank (bit 7 of L)
	jr     nz,DoCommandNote_not7D              ; 14C5  20 21
	ld     a,c                                 ; 14C7  79
	cp     $04                                 ; 14C8  FE 04
	jr     nz,DoCommandNote_music              ; 14CA  20 06
	ld     a,(MB_JingleState)                  ; 14CC  3A 59 0F
	or     a                                   ; 14CF  B7
	jr     nz,DoCommandNote_jingle             ; 14D0  20 0B
DoCommandNote_music:
	xor    a                                   ; 14D2  AF
	bit    7,l                                 ; 14D3  CB 7D
	jr     z,DoCommandNote_setbank             ; 14D5  28 02
	ld     a,$FF                               ; 14D7  3E FF
DoCommandNote_setbank:
	ld     (MB_VoiceBankHi),a                  ; 14D9  32 66 0F
	ret                                        ; 14DC  C9
DoCommandNote_jingle:
	xor    a                                   ; 14DD  AF
	bit    7,l                                 ; 14DE  CB 7D
	jr     z,DoCommandNote_setjbank            ; 14E0  28 02
	ld     a,$FF                               ; 14E2  3E FF
DoCommandNote_setjbank:
	ld     (MB_JingleBankHi),a                 ; 14E4  32 67 0F
	ret                                        ; 14E7  C9
DoCommandNote_not7D:
	cp     $7A                                 ; 14E8  FE 7A        $7A portamento speed, $7B pan, $7C FMS; $75-$79/$7E/$7F ignored
	jr     z,Cmd7A_Portamento                  ; 14EA  28 21
	cp     $7C                                 ; 14EC  FE 7C
	jr     z,Cmd7C_FMS                         ; 14EE  28 11
	cp     $7B                                 ; 14F0  FE 7B
	ret    nz                                  ; 14F2  C0
	ld     a,l                                 ; 14F3  7D           $7B: pan = (L&3) << 6 : 1 = right, 2 = left, 3 = both, 0 = voice pan
	and    $03                                 ; 14F4  E6 03
	rrca                                       ; 14F6  0F
	rrca                                       ; 14F7  0F
	ld     (iy+$0C),a                          ; 14F8  FD 77 0C
	ld     a,(iy+$08)                          ; 14FB  FD 7E 08
	jp     LoadChannelVoice                    ; 14FE  C3 4A 0C
Cmd7C_FMS:
	ld     a,l                                 ; 1501  7D           $7C: FMS (vibrato depth) = L&7, 0 = voice value
	and    $07                                 ; 1502  E6 07
	ld     (iy+$0B),a                          ; 1504  FD 77 0B
	ld     a,(iy+$08)                          ; 1507  FD 7E 08
	jp     LoadChannelVoice                    ; 150A  C3 4A 0C
Cmd7A_Portamento:
	ld     a,l                                 ; 150D  7D           $7A: portamento speed (F-number units per tick), 0 = off
	ld     (iy+$06),a                          ; 150E  FD 77 06
	ret                                        ; 1511  C9
StartSFXSample:
	ld     a,$FF                               ; 1512  3E FF        SFX sample requested by the 68k
	ld     (MB_SFXBusy),a                      ; 1514  32 90 0F     mark busy
	ld     a,(MB_SFXPan)                       ; 1517  3A 96 0F     pan: MB_SFXPan or L+R, patched into DAC_Poll
	or     a                                   ; 151A  B7
	ld     a,$C0                               ; 151B  3E C0
	jr     z,StartSFXSample_pan                ; 151D  28 03
	ld     a,(MB_SFXPan)                       ; 151F  3A 96 0F
StartSFXSample_pan:
	ld     (DAC_Poll_pan+1),a                  ; 1522  32 7A 15
	ld     a,(MB_SFXBank)                      ; 1525  3A 9A 0F     bank of the SFX sample
	call   SetBank                             ; 1528  CD BF 15     select the bank
	jr     StartSample                         ; 152B  18 10
StartMusicSample:
	ld     a,$C0                               ; 152D  3E C0        music drum: centred
	ld     (DAC_Poll_pan+1),a                  ; 152F  32 7A 15
	ld     a,(MB_MusicVol)                     ; 1532  3A 92 0F     music volume non-zero (fading) -> drums are dropped
	or     a                                   ; 1535  B7
	ret    nz                                  ; 1536  C0
	ld     a,(MB_MusicBank)                    ; 1537  3A 9C 0F     music sample bank
	call   SetBank                             ; 153A  CD BF 15     select the bank
StartSample:
	exx                                        ; 153D  D9           DAC on, load the player registers
	ld     a,$2B                               ; 153E  3E 2B
	ld     (YM_A0),a                           ; 1540  32 00 40
	rst    $08                                 ; 1543  CF
	ld     a,$80                               ; 1544  3E 80
	ld     (YM_D0),a                           ; 1546  32 01 40
	ld     hl,(MB_SmpAddr)                     ; 1549  2A 68 0F     skip the first 8 bytes
	ld     de,$0008                            ; 154C  11 08 00
	add    hl,de                               ; 154F  19
	ld     de,(MB_SmpRate)                     ; 1550  ED 5B 6A 0F  D = rate, E = phase
	ld     d,e                                 ; 1554  53
	ld     bc,(MB_SmpLen)                      ; 1555  ED 4B 6C 0F  BC = length - 12 (whole sample if shorter)
	ld     a,c                                 ; 1559  79
	sub    $0C                                 ; 155A  D6 0C
	ld     c,a                                 ; 155C  4F
	ld     a,b                                 ; 155D  78
	sbc    a,$00                               ; 155E  DE 00
	ld     b,a                                 ; 1560  47
	jr     nc,StartSample_go                   ; 1561  30 07
	ld     bc,(MB_SmpLen)                      ; 1563  ED 4B 6C 0F
	ld     hl,(MB_SmpAddr)                     ; 1567  2A 68 0F
StartSample_go:
	xor    a                                   ; 156A  AF
	ld     (MB_SmpTrigger),a                   ; 156B  32 6E 0F
	ld     (DAC_LastHi),a                      ; 156E  32 BE 15     leftover of revision 1 (last integer phase), never read
	rst    $08                                 ; 1571  CF
	exx                                        ; 1572  D9
	ret                                        ; 1573  C9

; --------------------------------------------------------------------------
;  DAC_Poll (alternate set): called from WaitCommand while BC' != 0
; --------------------------------------------------------------------------
DAC_Poll:
	ld     a,$B6                               ; 1574  3E B6        rewrite FM6 pan every poll (keeps it while voices are loaded)
	ld     (YM_A1),a                           ; 1576  32 02 40
DAC_Poll_pan:
	ld     a,$C0                               ; 1579  3E C0        SELF-MODIFIED: sample pan
	ld     (YM_D1),a                           ; 157B  32 03 40

; --------------------------------------------------------------------------
;  DAC_Poll (alternate set): called whenever BC' != 0
; --------------------------------------------------------------------------
	ld     a,d                                 ; 157E  7A           phase += rate; output one byte on carry
	add    a,e                                 ; 157F  83
	ld     e,a                                 ; 1580  5F
	ret    nc                                  ; 1581  D0
	ld     a,$2A                               ; 1582  3E 2A        reg $2A DAC data
	ld     (YM_A0),a                           ; 1584  32 00 40
	ld     a,(hl)                              ; 1587  7E           signed -> unsigned
	add    a,$80                               ; 1588  C6 80
	ld     (YM_D0),a                           ; 158A  32 01 40
	inc    hl                                  ; 158D  23
	dec    bc                                  ; 158E  0B
	ld     a,b                                 ; 158F  78
	or     c                                   ; 1590  B1
	ret    nz                                  ; 1591  C0
DAC_Poll_end:
	rst    $08                                 ; 1592  CF           end of sample: restore FM6 pan from its voice, DAC off
	ld     a,$B6                               ; 1593  3E B6        reg $B6 (FM6 pan) <- voice byte $19
	ld     (YM_A1),a                           ; 1595  32 02 40
	ld     a,(ChanState+$4E)                   ; 1598  3A 36 0F     voice of FM6
	ld     de,VoiceBank                        ; 159B  11 00 04
	ld     h,$00                               ; 159E  26 00
	ld     l,a                                 ; 15A0  6F
	add    hl,hl                               ; 15A1  29
	add    hl,hl                               ; 15A2  29
	add    hl,hl                               ; 15A3  29
	add    hl,hl                               ; 15A4  29
	add    hl,hl                               ; 15A5  29
	add    hl,de                               ; 15A6  19
	ld     de,$0019                            ; 15A7  11 19 00     +$19 = pan/AMS/FMS byte
	add    hl,de                               ; 15AA  19
	ld     a,(hl)                              ; 15AB  7E
	ld     (YM_D1),a                           ; 15AC  32 03 40
	ld     a,$2B                               ; 15AF  3E 2B        DAC off
	ld     (YM_A0),a                           ; 15B1  32 00 40
	rst    $08                                 ; 15B4  CF
	xor    a                                   ; 15B5  AF
	ld     (YM_D0),a                           ; 15B6  32 01 40
	ld     (MB_SFXBusy),a                      ; 15B9  32 90 0F     SFX no longer busy
	rst    $08                                 ; 15BC  CF
	ret                                        ; 15BD  C9
DAC_LastHi:
	db     $00                                 ; 15BE
SetBank:
	push   bc                                  ; 15BF  C5           A = bank (A15-A22); 9 serial writes to $6000, A23 = 0
	ld     b,$09                               ; 15C0  06 09
	ld     c,a                                 ; 15C2  4F
SetBank_bit:
	ld     a,c                                 ; 15C3  79
	and    $01                                 ; 15C4  E6 01
	ld     (BankReg),a                         ; 15C6  32 00 60
	srl    c                                   ; 15C9  CB 39
	djnz   SetBank_bit                         ; 15CB  10 F6
	pop    bc                                  ; 15CD  C1
	ret                                        ; 15CE  C9
NoteTable:
	dw     $0000,$0000,$0269,$028D,$02B4,$02DD,$0309,$0337,$0368,$039C,$03D3,$040D; 15CF  98 words: N=0,1 unused, N=2..97 = block 0-7 (B-1 .. A#7)
	dw     $044B,$048C,$0A69,$0A8D,$0AB4,$0ADD,$0B09,$0B37,$0B68,$0B9C,$0BD3,$0C0D; 15E7
	dw     $0C4B,$0C8C,$1269,$128D,$12B4,$12DD,$1309,$1337,$1368,$139C,$13D3,$140D; 15FF
	dw     $144B,$148C,$1A69,$1A8D,$1AB4,$1ADD,$1B09,$1B37,$1B68,$1B9C,$1BD3,$1C0D; 1617
	dw     $1C4B,$1C8C,$2269,$228D,$22B4,$22DD,$2309,$2337,$2368,$239C,$23D3,$240D; 162F
	dw     $244B,$248C,$2A69,$2A8D,$2AB4,$2ADD,$2B09,$2B37,$2B68,$2B9C,$2BD3,$2C0D; 1647
	dw     $2C4B,$2C8C,$3269,$328D,$32B4,$32DD,$3309,$3337,$3368,$339C,$33D3,$340D; 165F
	dw     $344B,$348C,$3A69,$3A8D,$3AB4,$3ADD,$3B09,$3B37,$3B68,$3B9C,$3BD3,$3C0D; 1677
	dw     $3C4B,$3C8C                         ; 168F
	db     $00,$41,$FA,$00                     ; 1693
