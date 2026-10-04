; Generated from the ROM by tools/zdis.py + z80_v1.py (labels/comments hand-written).
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
;  Revision 1 (Chuck Rock (E)): ROM $01CEA2 -> Z80 $0C00
;  ($1400 bytes copied, $0694 used).
;  The 68k does all sequencing (once per frame); the Z80 receives one
;  "row" (6 pattern cells) or a tick command per frame through the mailbox
;  at MB_Cmd and drives the YM2612 plus one PCM channel (FM6/DAC).
;  Compared with the later revisions there is no volume, pan, FMS or
;  portamento, the ROM bank is fixed by the boot stub (bank 2 =
;  $010000-$017FFF), and the DAC player writes a byte on every poll of the
;  main loop (the sample pointer advances by rate/256 per poll).
;
;  Channel state (IY, 7 bytes, ChanState + ch*7):
;    +00/01 slide step   +02/03 pitch (block<<11|fnum, bit 14 = key on)
;    +04 voice   +05/06 unused
;  Alternate registers while a sample plays: HL' = pointer, BC' = bytes left,
;  E' = rate, D' = integer phase.
; ==========================================================================
Start:
	di                                         ; 0C00  F3           reset entry (68k writes DI / JP $0C00 at Z80 $0000 after uploading the driver)
	im     1                                   ; 0C01  ED 56
	ld     sp,$1FFF                            ; 0C03  31 FF 1F
	ld     hl,Init_RstVectors                  ; 0C06  21 39 0C     copy RST $08/$10 handlers to $0008-$001E
	ld     de,$0008                            ; 0C09  11 08 00
	ld     bc,$0017                            ; 0C0C  01 17 00
	ldir                                       ; 0C0F  ED B0
	ld     hl,Init_IntVector                   ; 0C11  21 49 0C     copy "ei / ret" interrupt stub to $0038
	ld     de,$0038                            ; 0C14  11 38 00
	ld     bc,$0008                            ; 0C17  01 08 00
	ldir                                       ; 0C1A  ED B0
	ld     hl,Init_Vec0000                     ; 0C1C  21 33 0C     copy "nop / jp $0C00 / dw MB_Cmd" to $0000-$0005
	ld     de,$0000                            ; 0C1F  11 00 00
	ld     bc,$0006                            ; 0C22  01 06 00
	ldir                                       ; 0C25  ED B0
	ei                                         ; 0C27  FB           (interrupts enabled, but nothing raises one that matters: the handler is ei/ret)
	call   YM_Init                             ; 0C28  CD F4 0F     LFO on (6.02 Hz), Timer/CH3 mode off
	exx                                        ; 0C2B  D9           BC' = 0: no sample playing (alternate set = DAC player state)
	ld     bc,$0000                            ; 0C2C  01 00 00
	exx                                        ; 0C2F  D9
	jp     MainLoop                            ; 0C30  C3 92 0E
Init_Vec0000:
	db     $00,$C3,$00,$0C,$58,$0E             ; 0C33  -> $0000: nop / jp Start / dw MB_Cmd ($0004 = mailbox pointer read by the 68k)
Init_RstVectors:
	db     $3A,$00,$40,$CB,$7F,$20,$F9,$C9     ; 0C39  -> $0008 RST 08h and $0010 RST 10h: wait while the YM is busy
	db     $3A,$00,$40,$CB,$7F,$20,$F9,$C9     ; 0C41
Init_IntVector:
	db     $FB,$C9                             ; 0C49  -> $0038: ei / ret

; --------------------------------------------------------------------------
;  LoadVoice: write a 32-byte voice (26 registers) to channel C.
;  Voice layout: +00..03 DT/MUL, +04..07 TL, +08..0B KS/AR, +0C..0F AM/D1R,
;  +10..13 D2R, +14..17 D1L/RR (operator order 1,3,2,4), +18 FB/ALG,
;  +19 pan/AMS/FMS, +1A..1F unused.
; --------------------------------------------------------------------------
LoadVoice:
	push   bc                                  ; 0C4B  C5           A = voice number (bit 7 set = silent voice), C = channel 0-5
	ld     de,VoiceBank                        ; 0C4C  11 00 04
	ld     h,$00                               ; 0C4F  26 00
	ld     l,a                                 ; 0C51  6F
	add    hl,hl                               ; 0C52  29
	add    hl,hl                               ; 0C53  29
	add    hl,hl                               ; 0C54  29
	add    hl,hl                               ; 0C55  29
	add    hl,hl                               ; 0C56  29
	add    hl,de                               ; 0C57  19           HL = $0400 + voice*32
	bit    7,a                                 ; 0C58  CB 7F
	jr     z,LoadVoice_havevoice               ; 0C5A  28 03
	ld     hl,SilentVoice                      ; 0C5C  21 87 0C     bit 7: silent voice (TL=$7F)
LoadVoice_havevoice:
	ex     de,hl                               ; 0C5F  EB           DE = voice data, BC = channel*64
	ld     b,c                                 ; 0C60  41
	ld     c,$00                               ; 0C61  0E 00
	srl    b                                   ; 0C63  CB 38
	rr     c                                   ; 0C65  CB 19
	srl    b                                   ; 0C67  CB 38
	rr     c                                   ; 0C69  CB 19
	ld     hl,RegTable                         ; 0C6B  21 A7 0C     HL = register list for this channel
	add    hl,bc                               ; 0C6E  09
	ld     b,$40                               ; 0C6F  06 40        B = $40 -> YM port
	ex     af,af'                              ; 0C71  08
	ld     a,$1A                               ; 0C72  3E 1A        26 registers ($30-$8C, $B0, $B4); no volume, no overrides
LoadVoice_loop:
	ex     af,af'                              ; 0C74  08
	ld     c,(hl)                              ; 0C75  4E           C = port low byte (0 = part I, 2 = part II), A = register
	inc    hl                                  ; 0C76  23
	ld     a,(hl)                              ; 0C77  7E
	inc    hl                                  ; 0C78  23
	ld     (bc),a                              ; 0C79  02
	rst    $08                                 ; 0C7A  CF
	inc    c                                   ; 0C7B  0C
	ld     a,(de)                              ; 0C7C  1A
	ld     (bc),a                              ; 0C7D  02
	rst    $10                                 ; 0C7E  D7
	inc    de                                  ; 0C7F  13
	ex     af,af'                              ; 0C80  08
	dec    a                                   ; 0C81  3D
	jr     nz,LoadVoice_loop                   ; 0C82  20 F0
	ex     af,af'                              ; 0C84  08
	pop    bc                                  ; 0C85  C1
	ret                                        ; 0C86  C9

; ---------------------------------------------------------------------- data
SilentVoice:
	db     $00,$00,$00,$00,$7F,$7F,$7F,$7F     ; 0C87  "voice $80": all TL = $7F
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0C8F
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0C97
	db     $00,$00,$00,$00,$00,$00,$00,$00     ; 0C9F
RegTable:
	db     $00,$30,$00,$34,$00,$38,$00,$3C,$00,$40,$00,$44,$00,$48,$00,$4C; 0CA7  FM1: 32 x (port,reg): $30..$3C,$40..$4C,$50..$5C,$60..$6C,$70..$7C,$80..$8C,$B0,$B4,-,-,$90..$9C (only 26 used)
	db     $00,$50,$00,$54,$00,$58,$00,$5C,$00,$60,$00,$64,$00,$68,$00,$6C; 0CB7
	db     $00,$70,$00,$74,$00,$78,$00,$7C,$00,$80,$00,$84,$00,$88,$00,$8C; 0CC7
	db     $00,$B0,$00,$B4,$00,$00,$00,$00,$00,$90,$00,$94,$00,$98,$00,$9C; 0CD7
	db     $00,$31,$00,$35,$00,$39,$00,$3D,$00,$41,$00,$45,$00,$49,$00,$4D; 0CE7  FM2
	db     $00,$51,$00,$55,$00,$59,$00,$5D,$00,$61,$00,$65,$00,$69,$00,$6D; 0CF7
	db     $00,$71,$00,$75,$00,$79,$00,$7D,$00,$81,$00,$85,$00,$89,$00,$8D; 0D07
	db     $00,$B1,$00,$B5,$00,$00,$00,$00,$00,$91,$00,$95,$00,$99,$00,$9D; 0D17
	db     $00,$32,$00,$36,$00,$3A,$00,$3E,$00,$42,$00,$46,$00,$4A,$00,$4E; 0D27  FM3
	db     $00,$52,$00,$56,$00,$5A,$00,$5E,$00,$62,$00,$66,$00,$6A,$00,$6E; 0D37
	db     $00,$72,$00,$76,$00,$7A,$00,$7E,$00,$82,$00,$86,$00,$8A,$00,$8E; 0D47
	db     $00,$B2,$00,$B6,$00,$00,$00,$00,$00,$92,$00,$96,$00,$9A,$00,$9E; 0D57
	db     $02,$30,$02,$34,$02,$38,$02,$3C,$02,$40,$02,$44,$02,$48,$02,$4C; 0D67  FM4 (part II)
	db     $02,$50,$02,$54,$02,$58,$02,$5C,$02,$60,$02,$64,$02,$68,$02,$6C; 0D77
	db     $02,$70,$02,$74,$02,$78,$02,$7C,$02,$80,$02,$84,$02,$88,$02,$8C; 0D87
	db     $02,$B0,$02,$B4,$00,$00,$00,$00,$02,$90,$02,$94,$02,$98,$02,$9C; 0D97
	db     $02,$31,$02,$35,$02,$39,$02,$3D,$02,$41,$02,$45,$02,$49,$02,$4D; 0DA7  FM5
	db     $02,$51,$02,$55,$02,$59,$02,$5D,$02,$61,$02,$65,$02,$69,$02,$6D; 0DB7
	db     $02,$71,$02,$75,$02,$79,$02,$7D,$02,$81,$02,$85,$02,$89,$02,$8D; 0DC7
	db     $02,$B1,$02,$B5,$00,$00,$00,$00,$02,$91,$02,$95,$02,$99,$02,$9D; 0DD7
	db     $02,$32,$02,$36,$02,$3A,$02,$3E,$02,$42,$02,$46,$02,$4A,$02,$4E; 0DE7  FM6
	db     $02,$52,$02,$56,$02,$5A,$02,$5E,$02,$62,$02,$66,$02,$6A,$02,$6E; 0DF7
	db     $02,$72,$02,$76,$02,$7A,$02,$7E,$02,$82,$02,$86,$02,$8A,$02,$8E; 0E07
	db     $02,$B2,$02,$B6,$00,$00,$00,$00,$02,$92,$02,$96,$02,$9A,$02,$9E; 0E17

; ---------------------------------------------------------------------- RAM
;  ChanState: 6 x 7 bytes (FM1..FM6)
ChanState:
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E27  6 x 7 bytes, see header
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E2E
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E35
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E3C
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E43
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E4A
Unused_0E51:
	db     $00,$00,$00,$00,$00,$00,$00         ; 0E51

; --------------------------------------------------------------------------
;  Mailbox (68k writes with the bus held; its address is read from $0004)
; --------------------------------------------------------------------------
MB_Cmd:
	db     $00                                 ; 0E58  68k command: 1 tick, 2 reset, 3 load voice, 4 silence, 7 reload voices, other (10) = new row
MB_JingleState:
	db     $00                                 ; 0E59  $FF = jingle playing on FM5, 0 = none
MB_Notes:
	db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; 0E5A  6 pattern cells (lo,hi) for FM1-FM6; FM5 holds the jingle cell while a jingle plays
MB_VoiceBankHi:
	db     $00                                 ; 0E66  cmd $7D bit 7 for music: voices 32-63
MB_JingleBankHi:
	db     $00                                 ; 0E67  cmd $7D bit 7 for the jingle
MB_SmpAddr:
	dw     $1294                               ; 0E68  sample start ($8000 | offset in the fixed bank)
MB_SmpRate:
	db     $58                                 ; 0E6A  sample rate step (/256)
MB_SmpPhase:
	db     $00                                 ; 0E6B  initial integer phase (never written by the 68k)
MB_SmpLen:
	dw     $09A2                               ; 0E6C  sample length (bytes)
MB_SmpTrigger:
	db     $00                                 ; 0E6E  non-zero = start an SFX sample (68k)
MB_Pad_17:
	db     $00                                 ; 0E6F
MB_SampleTable:
	db     $00,$00,$00,$00                     ; 0E70  8 x (addr.hi, addr.lo, len.hi, len.lo), big-endian copy of the module sample table
	db     $00,$00,$00,$00                     ; 0E74
	db     $00,$00,$00,$00                     ; 0E78
	db     $00,$00,$00,$00                     ; 0E7C
	db     $00,$00,$00,$00                     ; 0E80
	db     $00,$00,$00,$00                     ; 0E84
	db     $00,$00,$00,$00                     ; 0E88
	db     $00,$00,$00,$00                     ; 0E8C
MB_SFXBusy:
	db     $00                                 ; 0E90  $FF while an SFX sample plays (music drums are ignored)
MB_Pad_39:
	db     $00                                 ; 0E91

; --------------------------------------------------------------------------
;  Main loop
; --------------------------------------------------------------------------
MainLoop:
	xor    a                                   ; 0E92  AF           command done: clear MB_Cmd (the 68k waits for 0 before writing the next one)
	ld     (MB_Cmd),a                          ; 0E93  32 58 0E
WaitCommand:
	ld     a,(MB_SmpTrigger)                   ; 0E96  3A 6E 0E     68k requested an SFX sample
	or     a                                   ; 0E99  B7
	call   nz,StartSFXSample                   ; 0E9A  C4 50 11
	exx                                        ; 0E9D  D9           sample playing?
	ld     a,b                                 ; 0E9E  78
	or     c                                   ; 0E9F  B1
	jr     z,WaitCommand_nodac                 ; 0EA0  28 03
	call   DAC_Poll                            ; 0EA2  CD 76 11     output one sample byte
WaitCommand_nodac:
	exx                                        ; 0EA5  D9
	ld     a,(MB_Cmd)                          ; 0EA6  3A 58 0E     wait for a command
	or     a                                   ; 0EA9  B7
	jr     z,WaitCommand                       ; 0EAA  28 EA
	cp     $01                                 ; 0EAC  FE 01        1: tick only
	jr     z,WaitCommand_tick                  ; 0EAE  28 40
	cp     $02                                 ; 0EB0  FE 02        2: reset
	jp     z,Cmd2_Reset                        ; 0EB2  CA 9C 10
	cp     $03                                 ; 0EB5  FE 03        3: load voice MB_Notes[0] on channel MB_Notes[1]
	jr     nz,WaitCommand_not3                 ; 0EB7  20 0C
	ld     a,(MB_Notes+1)                      ; 0EB9  3A 5B 0E
	ld     c,a                                 ; 0EBC  4F
	ld     a,(MB_Notes)                        ; 0EBD  3A 5A 0E
	call   LoadVoice                           ; 0EC0  CD 4B 0C
	jr     MainLoop                            ; 0EC3  18 CD
WaitCommand_not3:
	cp     $04                                 ; 0EC5  FE 04        4: silence
	jr     nz,WaitCommand_not4                 ; 0EC7  20 05
	call   Cmd4_Silence                        ; 0EC9  CD 55 10
	jr     MainLoop                            ; 0ECC  18 C4
WaitCommand_not4:
	cp     $07                                 ; 0ECE  FE 07        7: reload voices (resume)
	jp     z,Cmd7_ReloadVoices                 ; 0ED0  CA 83 10
	ld     b,$06                               ; 0ED3  06 06        otherwise: new row, IX = cells, IY = channel state
	ld     c,$00                               ; 0ED5  0E 00
	ld     ix,MB_Notes                         ; 0ED7  DD 21 5A 0E
	ld     iy,ChanState                        ; 0EDB  FD 21 27 0E
WaitCommand_rowloop:
	push   bc                                  ; 0EDF  C5
	call   DoNoteWord                          ; 0EE0  CD 48 0F
	inc    ix                                  ; 0EE3  DD 23
	inc    ix                                  ; 0EE5  DD 23
	ld     de,$0007                            ; 0EE7  11 07 00
	add    iy,de                               ; 0EEA  FD 19
	pop    bc                                  ; 0EEC  C1
	inc    c                                   ; 0EED  0C
	djnz   WaitCommand_rowloop                 ; 0EEE  10 EF
WaitCommand_tick:
	call   UpdateAllChannels                   ; 0EF0  CD F5 0E     apply slides
	jr     MainLoop                            ; 0EF3  18 9D

; --------------------------------------------------------------------------
;  Per-tick pitch slide
; --------------------------------------------------------------------------
UpdateAllChannels:
	ld     b,$06                               ; 0EF5  06 06        per-tick slide of all 6 channels
	ld     c,$00                               ; 0EF7  0E 00
	ld     iy,ChanState                        ; 0EF9  FD 21 27 0E
UpdateAllChannels_loop:
	call   Slide                               ; 0EFD  CD 09 0F
	ld     de,$0007                            ; 0F00  11 07 00
	add    iy,de                               ; 0F03  FD 19
	inc    c                                   ; 0F05  0C
	djnz   UpdateAllChannels_loop              ; 0F06  10 F5
	ret                                        ; 0F08  C9
Slide:
	ld     l,(iy+$00)                          ; 0F09  FD 6E 00     IY = channel: pitch += slide step (no block wrap in this revision)
	ld     h,(iy+$01)                          ; 0F0C  FD 66 01
	ld     a,h                                 ; 0F0F  7C
	or     l                                   ; 0F10  B5
	ret    z                                   ; 0F11  C8
	ld     e,(iy+$02)                          ; 0F12  FD 5E 02
	ld     d,(iy+$03)                          ; 0F15  FD 56 03
	add    hl,de                               ; 0F18  19
	ld     a,h                                 ; 0F19  7C
	and    $1F                                 ; 0F1A  E6 1F        (result unused)
	set    6,h                                 ; 0F1C  CB F4        keep key on
	ld     (iy+$02),l                          ; 0F1E  FD 75 02
	ld     (iy+$03),h                          ; 0F21  FD 74 03
	call   WriteFreqKey                        ; 0F24  CD 0D 10
	ret                                        ; 0F27  C9

; --------------------------------------------------------------------------
;  Row processing
; --------------------------------------------------------------------------
ApplyVoiceBank:
	push   af                                  ; 0F28  F5           A = voice; add 32 when the upper voice bank is selected (cmd $7D bit 7)
	ld     a,(MB_JingleState)                  ; 0F29  3A 59 0E
	or     a                                   ; 0F2C  B7
	jr     z,ApplyVoiceBank_music              ; 0F2D  28 0D
	ld     a,c                                 ; 0F2F  79           FM5 during a jingle uses the jingle flag
	cp     $04                                 ; 0F30  FE 04
	jr     nz,ApplyVoiceBank_music             ; 0F32  20 08
	ld     a,(MB_JingleBankHi)                 ; 0F34  3A 67 0E
	or     a                                   ; 0F37  B7
	jr     nz,ApplyVoiceBank_upper             ; 0F38  20 08
ApplyVoiceBank_lower:
	pop    af                                  ; 0F3A  F1
	ret                                        ; 0F3B  C9
ApplyVoiceBank_music:
	ld     a,(MB_VoiceBankHi)                  ; 0F3C  3A 66 0E
	or     a                                   ; 0F3F  B7
	jr     z,ApplyVoiceBank_lower              ; 0F40  28 F8
ApplyVoiceBank_upper:
	pop    af                                  ; 0F42  F1
	set    5,a                                 ; 0F43  CB EF
	ret                                        ; 0F45  C9
NoteWordTmp:
	dw     $0000                               ; 0F46  scratch: current cell

; DoNoteWord: one pattern cell, cell = hi:lo
;    hi bits 7-1 = N   (0 none, 1-$6C note, $6D-$74 drum sample, $75-$7F command)
;    hi bit 0 + lo bits 7-4 = I  (instrument 1-31, 0 = keep)
;    lo bits 3-0 = E   (pitch slide, sign/magnitude)
DoNoteWord:
	ld     l,(ix+$00)                          ; 0F48  DD 6E 00     IX = cell, IY = channel, C = channel (0-5)
	ld     h,(ix+$01)                          ; 0F4B  DD 66 01
	ld     a,h                                 ; 0F4E  7C           N = hi >> 1
	srl    a                                   ; 0F4F  CB 3F
	and    $7F                                 ; 0F51  E6 7F
	cp     $6D                                 ; 0F53  FE 6D        $6D-$7F: sample or command
	jp     nc,DoCommandNote                    ; 0F55  D2 28 11
	ld     a,h                                 ; 0F58  7C           empty cell
	or     l                                   ; 0F59  B5
	ret    z                                   ; 0F5A  C8
	ld     (NoteWordTmp),hl                    ; 0F5B  22 46 0F
	srl    h                                   ; 0F5E  CB 3C        HL >>= 1: L = instrument*8 + effect/2
	rr     l                                   ; 0F60  CB 1D
	ld     a,l                                 ; 0F62  7D           I = (cell >> 4) & $1F
	srl    a                                   ; 0F63  CB 3F
	srl    a                                   ; 0F65  CB 3F
	srl    a                                   ; 0F67  CB 3F
	and    $1F                                 ; 0F69  E6 1F
	jr     z,DoNoteWord_note                   ; 0F6B  28 0F
	dec    a                                   ; 0F6D  3D           voice = I-1 (+32)
	call   ApplyVoiceBank                      ; 0F6E  CD 28 0F
	cp     (iy+$04)                            ; 0F71  FD BE 04     reload only when the voice changes
	jr     z,DoNoteWord_note                   ; 0F74  28 06
	ld     (iy+$04),a                          ; 0F76  FD 77 04
	call   LoadVoice                           ; 0F79  CD 4B 0C
DoNoteWord_note:
	ld     hl,(NoteWordTmp)                    ; 0F7C  2A 46 0F     note N
	ld     a,h                                 ; 0F7F  7C
	srl    a                                   ; 0F80  CB 3F
	or     a                                   ; 0F82  B7
	jr     z,DoNoteWord_effect                 ; 0F83  28 36        N = 0: no note
	sla    a                                   ; 0F85  CB 27        pitch = NoteTable[N], key flag clear (re-trigger)
	ld     e,a                                 ; 0F87  5F
	ld     d,$00                               ; 0F88  16 00
	ld     hl,NoteTable                        ; 0F8A  21 D0 11
	add    hl,de                               ; 0F8D  19
	ld     a,(hl)                              ; 0F8E  7E
	inc    hl                                  ; 0F8F  23
	ld     h,(hl)                              ; 0F90  66
	ld     l,a                                 ; 0F91  6F
	ld     (iy+$02),l                          ; 0F92  FD 75 02
	ld     (iy+$03),h                          ; 0F95  FD 74 03
	ld     hl,$0000                            ; 0F98  21 00 00     clear slide
	ld     (iy+$00),l                          ; 0F9B  FD 75 00
	ld     (iy+$01),h                          ; 0F9E  FD 74 01
	ld     a,c                                 ; 0FA1  79           FM note on FM6 (no jingle, no SFX sample): stop the music sample
	cp     $05                                 ; 0FA2  FE 05
	jr     nz,DoNoteWord_effect                ; 0FA4  20 15
	ld     a,(MB_JingleState)                  ; 0FA6  3A 59 0E
	or     a                                   ; 0FA9  B7
	jr     nz,DoNoteWord_effect                ; 0FAA  20 0F
	ld     a,(MB_SFXBusy)                      ; 0FAC  3A 90 0E
	or     a                                   ; 0FAF  B7
	jr     nz,DoNoteWord_effect                ; 0FB0  20 09
	exx                                        ; 0FB2  D9
	ld     a,c                                 ; 0FB3  79
	or     b                                   ; 0FB4  B0
	jr     z,DoNoteWord_dacdone                ; 0FB5  28 03
	ld     bc,$0001                            ; 0FB7  01 01 00     BC' = 1: the sample ends on the next poll
DoNoteWord_dacdone:
	exx                                        ; 0FBA  D9
DoNoteWord_effect:
	ld     hl,(NoteWordTmp)                    ; 0FBB  2A 46 0F     effect nibble E: slide step = +/-(E&7)*4 per tick, bit 3 = down
	ld     a,l                                 ; 0FBE  7D
	and    $0F                                 ; 0FBF  E6 0F
	jr     z,DoNoteWord_key                    ; 0FC1  28 1A
	ld     h,a                                 ; 0FC3  67
	and    $07                                 ; 0FC4  E6 07
	bit    3,h                                 ; 0FC6  CB 5C
	jr     z,DoNoteWord_pos                    ; 0FC8  28 02
	cpl                                        ; 0FCA  2F
	inc    a                                   ; 0FCB  3C
DoNoteWord_pos:
	ld     l,a                                 ; 0FCC  6F
	ld     h,$00                               ; 0FCD  26 00
	bit    7,l                                 ; 0FCF  CB 7D
	jr     z,DoNoteWord_slidestore             ; 0FD1  28 02
	ld     h,$FF                               ; 0FD3  26 FF
DoNoteWord_slidestore:
	add    hl,hl                               ; 0FD5  29
	add    hl,hl                               ; 0FD6  29
	ld     (iy+$00),l                          ; 0FD7  FD 75 00
	ld     (iy+$01),h                          ; 0FDA  FD 74 01
DoNoteWord_key:
	ld     l,(iy+$02)                          ; 0FDD  FD 6E 02     key flag clear -> write key-off, then key-on
	ld     h,(iy+$03)                          ; 0FE0  FD 66 03
	bit    6,h                                 ; 0FE3  CB 74
	jr     nz,DoNoteWord_exit                  ; 0FE5  20 08
	call   WriteFreqKey                        ; 0FE7  CD 0D 10
	set    6,h                                 ; 0FEA  CB F4
	call   WriteFreqKey                        ; 0FEC  CD 0D 10
DoNoteWord_exit:
	set    6,(iy+$03)                          ; 0FEF  FD CB 03 F6
	ret                                        ; 0FF3  C9

; --------------------------------------------------------------------------
;  YM helpers
; --------------------------------------------------------------------------
YM_Init:
	ld     a,$22                               ; 0FF4  3E 22        reg $22 = $0C (LFO on, 6.02 Hz), reg $27 = 0
	ld     (YM_A0),a                           ; 0FF6  32 00 40
	rst    $08                                 ; 0FF9  CF
	ld     a,$0C                               ; 0FFA  3E 0C
	ld     (YM_D0),a                           ; 0FFC  32 01 40
	rst    $10                                 ; 0FFF  D7
	ld     a,$27                               ; 1000  3E 27
	ld     (YM_A0),a                           ; 1002  32 00 40
	rst    $08                                 ; 1005  CF
	ld     a,$00                               ; 1006  3E 00
	ld     (YM_D0),a                           ; 1008  32 01 40
	rst    $10                                 ; 100B  D7
	ret                                        ; 100C  C9
WriteFreqKey:
	push   hl                                  ; 100D  E5           HL = block/F-num word, bit 14 = key on; C = channel
	push   bc                                  ; 100E  C5
	ld     e,$00                               ; 100F  1E 00
	ld     a,c                                 ; 1011  79
	cp     $03                                 ; 1012  FE 03
	jr     c,WriteFreqKey_part                 ; 1014  38 05
	sub    $03                                 ; 1016  D6 03
	ld     c,a                                 ; 1018  4F
	ld     e,$02                               ; 1019  1E 02
WriteFreqKey_part:
	ld     d,$40                               ; 101B  16 40
	ld     a,c                                 ; 101D  79
	add    a,$A4                               ; 101E  C6 A4        $A4+ch: block/F-num hi
	ld     (de),a                              ; 1020  12
	rst    $08                                 ; 1021  CF
	inc    de                                  ; 1022  13
	ld     a,h                                 ; 1023  7C
	and    $3F                                 ; 1024  E6 3F
	ld     (de),a                              ; 1026  12
	rst    $10                                 ; 1027  D7
	dec    de                                  ; 1028  1B
	ld     a,c                                 ; 1029  79
	add    a,$A0                               ; 102A  C6 A0        $A0+ch: F-num lo
	ld     (de),a                              ; 102C  12
	rst    $08                                 ; 102D  CF
	inc    de                                  ; 102E  13
	ld     a,l                                 ; 102F  7D
	ld     (de),a                              ; 1030  12
	dec    de                                  ; 1031  1B
	rst    $10                                 ; 1032  D7
	pop    bc                                  ; 1033  C1
	push   bc                                  ; 1034  C5
	ld     a,c                                 ; 1035  79           key code: 0,1,2,4,5,6
	and    $07                                 ; 1036  E6 07
	cp     $03                                 ; 1038  FE 03
	jr     c,WriteFreqKey_keycode              ; 103A  38 01
	inc    a                                   ; 103C  3C
WriteFreqKey_keycode:
	ld     c,$00                               ; 103D  0E 00
	bit    6,h                                 ; 103F  CB 74        bit 6 of H -> key on all operators
	jr     z,WriteFreqKey_keyoff               ; 1041  28 02
	ld     c,$F0                               ; 1043  0E F0
WriteFreqKey_keyoff:
	or     c                                   ; 1045  B1
	ex     af,af'                              ; 1046  08
	ld     a,$28                               ; 1047  3E 28        reg $28
	ld     de,YM_A0                            ; 1049  11 00 40
	ld     (de),a                              ; 104C  12
	rst    $08                                 ; 104D  CF
	inc    e                                   ; 104E  1C
	ex     af,af'                              ; 104F  08
	ld     (de),a                              ; 1050  12
	rst    $10                                 ; 1051  D7
	pop    bc                                  ; 1052  C1
	pop    hl                                  ; 1053  E1
	ret                                        ; 1054  C9

; --------------------------------------------------------------------------
;  Commands 4, 7, 2
; --------------------------------------------------------------------------
Cmd4_Silence:
	ld     a,(MB_JingleState)                  ; 1055  3A 59 0E     silence all channels (FM5 is skipped during a jingle)
	ld     (Cmd4_Silence_jflag+1),a            ; 1058  32 6F 10     SELF-MODIFY Cmd4_Silence_jflag ("ld a,0") with the jingle state
	exx                                        ; 105B  D9           stop any playing sample
	ld     a,c                                 ; 105C  79
	or     b                                   ; 105D  B0
	jr     z,Cmd4_Silence_chans                ; 105E  28 03
	ld     bc,$0001                            ; 1060  01 01 00
Cmd4_Silence_chans:
	exx                                        ; 1063  D9
	ld     b,$06                               ; 1064  06 06
	ld     c,$00                               ; 1066  0E 00
Cmd4_Silence_loop:
	push   bc                                  ; 1068  C5
	ld     a,c                                 ; 1069  79
	cp     $04                                 ; 106A  FE 04
	jr     nz,Cmd4_Silence_silence             ; 106C  20 05
Cmd4_Silence_jflag:
	ld     a,$00                               ; 106E  3E 00
	or     a                                   ; 1070  B7
	jr     nz,Cmd4_Silence_next                ; 1071  20 05
Cmd4_Silence_silence:
	ld     a,$80                               ; 1073  3E 80        silent voice
	call   LoadVoice                           ; 1075  CD 4B 0C
Cmd4_Silence_next:
	pop    bc                                  ; 1078  C1
	inc    c                                   ; 1079  0C
	djnz   Cmd4_Silence_loop                   ; 107A  10 EC
	ret                                        ; 107C  C9
KeyCodeTable:
	db     $00,$01,$02,$04,$05,$06             ; 107D  unused key-code table
Cmd7_ReloadVoices:
	ld     iy,ChanState                        ; 1083  FD 21 27 0E  reload the voice of every channel (end of pause)
	ld     b,$06                               ; 1087  06 06
	ld     c,$00                               ; 1089  0E 00
Cmd7_ReloadVoices_loop:
	ld     a,(iy+$04)                          ; 108B  FD 7E 04
	call   LoadVoice                           ; 108E  CD 4B 0C
	ld     de,$0007                            ; 1091  11 07 00
	add    iy,de                               ; 1094  FD 19
	inc    c                                   ; 1096  0C
	djnz   Cmd7_ReloadVoices_loop              ; 1097  10 F2
	jp     MainLoop                            ; 1099  C3 92 0E
Cmd2_Reset:
	ld     hl,$0000                            ; 109C  21 00 00     stop: clear slides, set "no key" pitch, invalidate voices (FM5 kept during a jingle)
	ld     (ChanState),hl                      ; 109F  22 27 0E
	ld     (ChanState+$07),hl                  ; 10A2  22 2E 0E
	ld     (ChanState+$0E),hl                  ; 10A5  22 35 0E
	ld     (ChanState+$15),hl                  ; 10A8  22 3C 0E
	ld     (ChanState+$23),hl                  ; 10AB  22 4A 0E
	ld     a,(MB_JingleState)                  ; 10AE  3A 59 0E
	or     a                                   ; 10B1  B7
	jr     nz,Cmd2_Reset_freq                  ; 10B2  20 03
	ld     (ChanState+$1C),hl                  ; 10B4  22 43 0E
Cmd2_Reset_freq:
	ld     h,$20                               ; 10B7  26 20
	ld     (ChanState+$02),hl                  ; 10B9  22 29 0E
	ld     (ChanState+$09),hl                  ; 10BC  22 30 0E
	ld     (ChanState+$10),hl                  ; 10BF  22 37 0E
	ld     (ChanState+$17),hl                  ; 10C2  22 3E 0E
	ld     (ChanState+$25),hl                  ; 10C5  22 4C 0E
	or     a                                   ; 10C8  B7
	jr     nz,Cmd2_Reset_voices                ; 10C9  20 03
	ld     (ChanState+$1E),hl                  ; 10CB  22 45 0E
Cmd2_Reset_voices:
	ld     a,$FF                               ; 10CE  3E FF
	ld     (ChanState+$04),a                   ; 10D0  32 2B 0E
	ld     (ChanState+$0B),a                   ; 10D3  32 32 0E
	ld     (ChanState+$12),a                   ; 10D6  32 39 0E
	ld     (ChanState+$19),a                   ; 10D9  32 40 0E
	ld     (ChanState+$27),a                   ; 10DC  32 4E 0E
	ld     a,(MB_JingleState)                  ; 10DF  3A 59 0E
	or     a                                   ; 10E2  B7
	jp     nz,MainLoop                         ; 10E3  C2 92 0E
	ld     a,$FF                               ; 10E6  3E FF
	ld     (ChanState+$20),a                   ; 10E8  32 47 0E
	jp     MainLoop                            ; 10EB  C3 92 0E

; --------------------------------------------------------------------------
;  Samples and command notes
; --------------------------------------------------------------------------
MusicSampleNote:
	cp     $6D                                 ; 10EE  FE 6D        N $6D-$74: drum sample (N-$6D) on FM6 only, L = rate
	ret    c                                   ; 10F0  D8
	sub    $6D                                 ; 10F1  D6 6D
	ex     af,af'                              ; 10F3  08
	ld     a,c                                 ; 10F4  79
	cp     $05                                 ; 10F5  FE 05
	ret    nz                                  ; 10F7  C0
	ex     af,af'                              ; 10F8  08
	push   bc                                  ; 10F9  C5
	push   hl                                  ; 10FA  E5
	push   de                                  ; 10FB  D5
	ld     c,l                                 ; 10FC  4D
	add    a,a                                 ; 10FD  87
	add    a,a                                 ; 10FE  87
	ld     l,a                                 ; 10FF  6F
	ld     a,(MB_SFXBusy)                      ; 1100  3A 90 0E     SFX sample has priority
	or     a                                   ; 1103  B7
	jr     nz,MusicSampleNote_exit             ; 1104  20 1E
	ld     a,c                                 ; 1106  79           rate
	ld     (MB_SmpRate),a                      ; 1107  32 6A 0E
	ld     h,$00                               ; 110A  26 00
	ld     de,MB_SampleTable                   ; 110C  11 70 0E     MB_SampleTable + 4*n
	add    hl,de                               ; 110F  19
	ld     b,(hl)                              ; 1110  46
	inc    hl                                  ; 1111  23
	ld     c,(hl)                              ; 1112  4E
	inc    hl                                  ; 1113  23
	ld     d,(hl)                              ; 1114  56
	inc    hl                                  ; 1115  23
	ld     e,(hl)                              ; 1116  5E
	set    7,b                                 ; 1117  CB F8        Z80 bank window $8000-$FFFF (bank fixed by the boot stub)
	ld     (MB_SmpAddr),bc                     ; 1119  ED 43 68 0E
	ld     (MB_SmpLen),de                      ; 111D  ED 53 6C 0E
	call   StartSample                         ; 1121  CD 55 11
MusicSampleNote_exit:
	pop    de                                  ; 1124  D1
	pop    hl                                  ; 1125  E1
	pop    bc                                  ; 1126  C1
	ret                                        ; 1127  C9
DoCommandNote:
	cp     $75                                 ; 1128  FE 75        N >= $6D: $6D-$74 drum sample, $7D voice bank; everything else ignored here
	jr     c,MusicSampleNote                   ; 112A  38 C2
	cp     $7D                                 ; 112C  FE 7D        $7D: speed (68k) / voice bank (bit 7 of L)
	ret    nz                                  ; 112E  C0
	ld     a,c                                 ; 112F  79
	cp     $04                                 ; 1130  FE 04
	jr     nz,DoCommandNote_music              ; 1132  20 06
	ld     a,(MB_JingleState)                  ; 1134  3A 59 0E
	or     a                                   ; 1137  B7
	jr     nz,DoCommandNote_jingle             ; 1138  20 0B
DoCommandNote_music:
	xor    a                                   ; 113A  AF
	bit    7,l                                 ; 113B  CB 7D
	jr     z,DoCommandNote_setbank             ; 113D  28 02
	ld     a,$FF                               ; 113F  3E FF
DoCommandNote_setbank:
	ld     (MB_VoiceBankHi),a                  ; 1141  32 66 0E
	ret                                        ; 1144  C9
DoCommandNote_jingle:
	xor    a                                   ; 1145  AF
	bit    7,l                                 ; 1146  CB 7D
	jr     z,DoCommandNote_setjbank            ; 1148  28 02
	ld     a,$FF                               ; 114A  3E FF
DoCommandNote_setjbank:
	ld     (MB_JingleBankHi),a                 ; 114C  32 67 0E
	ret                                        ; 114F  C9
StartSFXSample:
	ld     a,$FF                               ; 1150  3E FF        SFX sample requested by the 68k: mark busy
	ld     (MB_SFXBusy),a                      ; 1152  32 90 0E
StartSample:
	exx                                        ; 1155  D9           DAC on, load the player registers
	ld     a,$2B                               ; 1156  3E 2B
	ld     (YM_A0),a                           ; 1158  32 00 40
	rst    $08                                 ; 115B  CF
	ld     a,$80                               ; 115C  3E 80
	ld     (YM_D0),a                           ; 115E  32 01 40
	ld     hl,(MB_SmpAddr)                     ; 1161  2A 68 0E     HL' = start (no bytes skipped in this revision)
	ld     de,(MB_SmpRate)                     ; 1164  ED 5B 6A 0E  E' = rate, D' = integer phase
	ld     bc,(MB_SmpLen)                      ; 1168  ED 4B 6C 0E  BC' = length
	xor    a                                   ; 116C  AF
	ld     (MB_SmpTrigger),a                   ; 116D  32 6E 0E
	ld     (DAC_LastHi),a                      ; 1170  32 CF 11
	rst    $08                                 ; 1173  CF
	exx                                        ; 1174  D9
	ret                                        ; 1175  C9

; --------------------------------------------------------------------------
;  DAC_Poll (alternate set): called from WaitCommand while BC' != 0
; --------------------------------------------------------------------------
DAC_Poll:
	ld     a,$2A                               ; 1176  3E 2A        output the current byte on every poll; advance when the integer phase changes
	ld     (YM_A0),a                           ; 1178  32 00 40
	ld     a,(hl)                              ; 117B  7E           signed -> unsigned
	add    a,$80                               ; 117C  C6 80
	ld     (YM_D0),a                           ; 117E  32 01 40
	ld     a,(MB_SmpRate)                      ; 1181  3A 6A 0E     phase += rate
	add    a,e                                 ; 1184  83
	ld     e,a                                 ; 1185  5F
	ld     a,$B6                               ; 1186  3E B6        FM6 pan register ($B6, part II)
	ld     (YM_A1),a                           ; 1188  32 02 40
	ld     a,d                                 ; 118B  7A
	adc    a,$00                               ; 118C  CE 00
	ld     d,a                                 ; 118E  57
	ld     a,(DAC_LastHi)                      ; 118F  3A CF 11     integer part changed?
	cp     d                                   ; 1192  BA
	ld     a,d                                 ; 1193  7A
	ld     (DAC_LastHi),a                      ; 1194  32 CF 11
	jr     z,DAC_Poll_pan                      ; 1197  28 02
	inc    hl                                  ; 1199  23           advance
	dec    bc                                  ; 119A  0B
DAC_Poll_pan:
	ld     a,$C0                               ; 119B  3E C0        FM6 pan = L+R
	ld     (YM_D1),a                           ; 119D  32 03 40
	ld     a,b                                 ; 11A0  78
	or     c                                   ; 11A1  B1
	ret    nz                                  ; 11A2  C0
DAC_Poll_end:
	rst    $08                                 ; 11A3  CF           end of sample: restore FM6 pan from its voice
	ld     a,$B6                               ; 11A4  3E B6
	ld     (YM_A1),a                           ; 11A6  32 02 40
	ld     a,(ChanState+$27)                   ; 11A9  3A 4E 0E     voice of FM6
	ld     de,VoiceBank                        ; 11AC  11 00 04
	ld     h,$00                               ; 11AF  26 00
	ld     l,a                                 ; 11B1  6F
	add    hl,hl                               ; 11B2  29
	add    hl,hl                               ; 11B3  29
	add    hl,hl                               ; 11B4  29
	add    hl,hl                               ; 11B5  29
	add    hl,hl                               ; 11B6  29
	add    hl,de                               ; 11B7  19
	ld     de,$0019                            ; 11B8  11 19 00     +$19 = pan/AMS/FMS byte
	add    hl,de                               ; 11BB  19
	ld     a,(hl)                              ; 11BC  7E
	ld     (YM_D1),a                           ; 11BD  32 03 40
	ld     a,$2B                               ; 11C0  3E 2B        DAC off
	ld     (YM_A0),a                           ; 11C2  32 00 40
	rst    $08                                 ; 11C5  CF
	xor    a                                   ; 11C6  AF
	ld     (YM_D0),a                           ; 11C7  32 01 40
	ld     (MB_SFXBusy),a                      ; 11CA  32 90 0E     SFX no longer busy
	rst    $08                                 ; 11CD  CF
	ret                                        ; 11CE  C9
DAC_LastHi:
	db     $00                                 ; 11CF  last integer phase

; --------------------------------------------------------------------------
;  Note table (word = block<<11 | F-number)
; --------------------------------------------------------------------------
NoteTable:
	dw     $0000,$0000,$0269,$028D,$02B4,$02DD,$0309,$0337,$0368,$039C,$03D3,$040D; 11D0  98 words: N=0,1 unused, N=2..97 = block 0-7, 12 notes each (B-1 .. A#7, PAL-tuned)
	dw     $044B,$048C,$0A69,$0A8D,$0AB4,$0ADD,$0B09,$0B37,$0B68,$0B9C,$0BD3,$0C0D; 11E8
	dw     $0C4B,$0C8C,$1269,$128D,$12B4,$12DD,$1309,$1337,$1368,$139C,$13D3,$140D; 1200
	dw     $144B,$148C,$1A69,$1A8D,$1AB4,$1ADD,$1B09,$1B37,$1B68,$1B9C,$1BD3,$1C0D; 1218
	dw     $1C4B,$1C8C,$2269,$228D,$22B4,$22DD,$2309,$2337,$2368,$239C,$23D3,$240D; 1230
	dw     $244B,$248C,$2A69,$2A8D,$2AB4,$2ADD,$2B09,$2B37,$2B68,$2B9C,$2BD3,$2C0D; 1248
	dw     $2C4B,$2C8C,$3269,$328D,$32B4,$32DD,$3309,$3337,$3368,$339C,$33D3,$340D; 1260
	dw     $344B,$348C,$3A69,$3A8D,$3AB4,$3ADD,$3B09,$3B37,$3B68,$3B9C,$3BD3,$3C0D; 1278
	dw     $3C4B,$3C8C                         ; 1290
