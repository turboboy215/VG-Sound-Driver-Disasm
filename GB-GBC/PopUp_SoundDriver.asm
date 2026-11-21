; =====================================================================
; Pop Up (U) [!] - Game Boy, Infogrames 1991
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 1
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o popup.o PopUp_SoundDriver.asm
;   rgblink -t -o popup.gb popup.o
;   python tools/cmp_ranges.py popup.gb "Pop Up (U) [!].gb" <ranges listed in the doc>
; (-t: 32 KB ROM without MBC, so $4000-$7FFF is plain ROM.)
;
; Documentation: PopUp_SoundDriver.md / AJG_SoundEngine_Family.md
; =====================================================================


; ---- pitch names: NOTE <pitch>, <octave> ; byte = (octave - 1) * 12 + pitch
; note byte 12 = C2 = first entry of the period table (65.4 Hz on CH1/CH2).
DEF C_ EQU 0
DEF Csh EQU 1
DEF D_ EQU 2
DEF Dsh EQU 3
DEF E_ EQU 4
DEF F_ EQU 5
DEF Fsh EQU 6
DEF G_ EQU 7
DEF Gsh EQU 8
DEF A_ EQU 9
DEF Ash EQU 10
DEF B_ EQU 11

MACRO NOTE
	db (\2 - 1) * 12 + \1
ENDM

; ---- stream commands (patterns, SFX streams and instrument macros) ----
MACRO LEN       ; note length in ticks, 1-33
	db $DE + \1
ENDM
MACRO VOL       ; start volume of following notes, 0-15
	db $BF + \1
ENDM
MACRO VOLENV    ; start volume + envelope: atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $CF + \1, \2, \3, \4
ENDM
MACRO INSTR     ; run instrument macro 0-25
	db $80 + \1
ENDM
MACRO ARP       ; arpeggio table 0-14
	db $B0 + \1
ENDM
MACRO PLAY_SFX  ; start sound id 0-21, then wait one note length
	db $9A + \1
ENDM
MACRO GLIDE
	db $60
	db \1
ENDM
MACRO RELEASE
	db $61
	db \1
	db \2
ENDM
MACRO ARP_OFF
	db $62
ENDM
MACRO SLIDE
	db $63
	db \1
	db \2
	db \3
ENDM
MACRO BEND
	db $64
	db \1
	db \2
	db \3
	db \4
	db \5
ENDM
MACRO BEND_OFF
	db $65
ENDM
MACRO VIBRATO
	db $66
	db \1
	db \2
	db \3
ENDM
MACRO VIBRATO_OFF
	db $67
ENDM
MACRO MASK_A
	db $68
ENDM
MACRO MASK_B
	db $69
ENDM
MACRO MASK_AB
	db $6A
ENDM
MACRO WAIT
	db $6B
ENDM
MACRO REST
	db $6C
ENDM
MACRO STOP_ALL
	db $6D
ENDM
MACRO CHORUS_ON
	db $6E
ENDM
MACRO CHORUS_OFF
	db $6F
ENDM
MACRO END
	db $70
ENDM
MACRO GLIDE_OFF
	db $71
ENDM
MACRO TRANSPOSE
	db $72
	db \1
ENDM
MACRO NEXT
	db $73
ENDM
MACRO ORDER_JUMP
	db $74
	dw \1
ENDM
MACRO ATTEN
	db $75
	db \1
ENDM
MACRO LENGTH
	db $76
	db \1
ENDM
MACRO NOTE_OFF
	db $77
ENDM
MACRO NOISE_HIT1
	db $78
ENDM
MACRO PAN_C
	db $79
ENDM
MACRO PAN_R
	db $7A
ENDM
MACRO PAN_L
	db $7B
ENDM
MACRO DUTY_50
	db $7C
ENDM
MACRO DUTY_75
	db $7D
ENDM
MACRO DUTY_12
	db $7E
ENDM
MACRO NOISE_HIT2
	db $7F
ENDM
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
	dw 0, \1
ENDM
; ---- arpeggio tables ----
DEF ARP_LOOP EQU $73   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry

; ---- routines outside the disassembled ranges ----
DEF X161B EQU $161B
DEF MemCopy EQU $191D
DEF X1E1C EQU $1E1C
DEF XFF80 EQU $FF80

; ---- RAM / HRAM ----
DEF wCh1 EQU $C100
DEF wCh1FreqLo EQU $C107
DEF wCh1FreqHi EQU $C109
DEF wCh1Vol EQU $C10B
DEF wCh2 EQU $C200
DEF wCh3 EQU $C300
DEF wSfxLockedVol EQU $C339
DEF wSfx EQU $C400
DEF wSfxPtr EQU $C402
DEF wSfxId EQU $C430
DEF hSavedIE EQU $FFC2
DEF hLCDOff EQU $FFCD
DEF hSfxLock EQU $FFDF
DEF hShNR12 EQU $FFE0
DEF hShNR22 EQU $FFE1
DEF hShNR32 EQU $FFE2
DEF hShNR14 EQU $FFE5
DEF hShNR24 EQU $FFE6
DEF hShNR34 EQU $FFE7
DEF hInInstr EQU $FFE8
DEF hTranspose EQU $FFE9
DEF hReg6 EQU $FFEC
DEF hMask EQU $FFED
DEF hMaskSaved EQU $FFEE
DEF hSfxAtten EQU $FFEF
DEF hMusAtten EQU $FFF0
DEF hShNR51 EQU $FFF1
DEF hShNR11 EQU $FFF2
DEF hShNR21 EQU $FFF3
DEF hCh1NoteFlag EQU $FFF4
DEF hSndOn EQU $FFF5

; ---- hardware registers (subset of hardware.inc) ----
DEF rTIMA EQU $FF05
DEF rTMA EQU $FF06
DEF rTAC EQU $FF07
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF _AUD3WAVERAM EQU $FF30
DEF rLCDC EQU $FF40
DEF rSTAT EQU $FF41
DEF rLY EQU $FF44
DEF rBGP EQU $FF47
DEF rOBP0 EQU $FF48
DEF rOBP1 EQU $FF49
DEF rIE EQU $FFFF


; rst $08: hl = [hl] (game code, used by the driver)
SECTION "RST08_ReadPtr", ROM0[$0008]

Rst08_ReadPtr:
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

; rst $10: jp hl
SECTION "RST10_JumpHL", ROM0[$0010]

Rst10_JumpHL:
	jp hl

; rst $20: [de++] = [hl++], bc-- (flags/af kept)
SECTION "RST20_CopyByte", ROM0[$0020]

Rst20_CopyByte:
	push af
	ld a, [hli]
	ld [de], a
	inc de
	pop af
	dec bc
	ret

; rst $28: swap hl and de
SECTION "RST28_SwapHLDE", ROM0[$0028]

Rst28_SwapHLDE:
	push hl
	push de
	pop hl
	pop de
	ret

; Timer interrupt vector
SECTION "TimerVector", ROM0[$0050]

TimerVec:
	jp TimerISR

; Game code (part of the boot routine at $06B3): zeroes $C100-$C4FF, sets the
; per-channel register indices and NR51/mask bits, copies the CH1 page to the
; SFX page, fills wave RAM, sets duty, NR50/NR52, clears FF10-FF23, NR30 on.
; The driver itself never writes fields $06/$08/$0A/$1F/$20.
SECTION "GameSndInit", ROM0[$06FE]

GameSndInit:
	ld hl, wCh1
	ld de, $C101
	ld bc, $03FF
	ld [hl], l
	rst $00
	ld h, $C1
	ld b, $03
	xor a
	ld c, $08
	ld d, $01
	ld e, $08
L0714:
	ld l, $06
	ld [hli], a
	inc a
	inc l
	ld [hli], a
	inc a
	inc l
	ld [hl], c
	inc c
	ld l, $1F
	ld [hl], d
	inc l
	ld [hl], e
	rlc d
	rlc e
	inc h
	dec b
	jr nz, L0714
	ld hl, wCh1
	ld de, wSfx
	ld bc, $0100
	rst $00
	ld hl, $FF30
	ld b, $10
	ld a, $0F
L073C:
	ld [hli], a
	dec b
	jr nz, L073C
	ld a, $80
	ldh [hShNR11], a
	ldh [hShNR21], a
	ldh [rNR11], a
	ldh [rNR21], a
	ld a, $FF
	ldh [rNR50], a
	ld a, $8F
	ldh [rNR52], a
	ld hl, $FF10
	ld b, $14
	xor a
L0758:
	ld [hli], a
	dec b
	jr nz, L0758
	ld a, $80
	ldh [rNR30], a

; Game VBlank handler: runs SndUpdate while wSndOn != 0 (the call at $1610 is HRAM OAM DMA)
SECTION "VBlankSndHook", ROM0[$1610]

VBlankSndHook:
	call XFF80
	ldh a, [hSndOn]
	and a
	jr z, X161B
	call SndUpdate

; Game helper used as "call bc": push bc / ret
SECTION "CallBC", ROMX[$4903], BANK[1]

CallBC:
	push bc
	ret

SECTION "SoundDriver", ROMX[$50A0], BANK[1]


; 22 bytes that nothing references (not used by the game or the driver).
OrphanTable_50A0:
	db $20, $00, $40, $06, $37, $01, $3F, $02, $A0, $0C, $C0, $12, $E0, $18, $20, $00
	db $40, $01, $60, $02, $80, $03

; PlaySound while hSfxLock is set: the request is dropped.
; BUG: clears byte $39 of page h, and h is whatever the caller had in h
; (from the game this writes to an arbitrary RAM page).
PlaySound_Locked:
	pop af
	ld l, $39
	ld [hl], $00
	ret

; PlaySoundChecked (a = id): skip if hSfxAtten = $0F, else PlaySoundLock.
; Not called by the game.
PlaySoundChecked:
	push af
	push de
	push bc
	push hl
	ld c, a
	ldh a, [hSfxAtten]
	cp $0F
	jp z, L50CC
	ld a, c
	call PlaySoundLock
L50CC:
	pop hl
	pop bc
	pop de
	pop af
	ret

; PlaySoundLock: stop the current SFX, start sound a, and set hSfxLock so that
; later PlaySound calls are ignored until this SFX ends. Only reached from
; PlaySoundChecked.
PlaySoundLock:
	push af
	ld hl, wSfxId
	ld a, [hl]
	and a
	call nz, StopSfx
	xor a
	ld [wSfxLockedVol], a
	inc a
	ldh [hSfxLock], a
	jp PlaySound_Start

; PlaySound (a = sound id 1-7): public entry, keeps bc/de/hl.
; Stops a running SFX, saves hMask, starts the stream on the SFX page ($C4xx)
; and parses its first tick immediately (inside the call).
PlaySound:
	push hl
	push de
	push bc
	call PlaySound_
	pop bc
	pop de
	pop hl
	ret
PlaySound_:
	push af
	ldh a, [hSfxLock]
	and a
	jp nz, PlaySound_Locked
	ld hl, wSfxId
	ld a, [hl]
	and a
	call nz, StopSfx
PlaySound_Start:
	pop af
	ld l, $30
	ld [hl], a
	ld de, wSfxPtr
	push af
	ldh a, [hMask]
	ldh [hMaskSaved], a
	pop af
	jp StartSfxStream

; Sound table lookup: SfxTable_m2 + 2*id. Only [$C402/3] (stream pointer) is set,
; not the order-list pointer, and the rest of the SFX page keeps its old state.
StartSfxStream:
	add a, a
	add a, LOW(SfxTable - 2)
	ld l, a
	adc a, HIGH(SfxTable - 2)
	sub l
	ld h, a
	rst $20
	rst $28
	ld a, [de]
	ld [hl], a
	ld d, a
	dec l
	ld e, [hl]
	jp ReadStream

; Timer interrupt (TMA=$B4, TAC=4: 4096/76 = 53.89 Hz). Runs SndUpdate only while
; the LCD is off (hLCDOff = 0) and hSndOn != 0. With the LCD on the VBlank
; handler calls SndUpdate instead (59.73 Hz).
TimerISR:
	push hl
	push de
	push bc
	push af
	ldh a, [hLCDOff]
	and a
	jr nz, L5130
	ldh a, [hSndOn]
	and a
	jr z, L5130
	call SndUpdate
L5130:
	pop af
	pop bc
	pop de
	pop hl
	reti

; SndUpdate: one driver tick. NR50 = $FF and NR52 = $8F every tick.
; Ticks the four pages (Ch1, Ch2, Ch3, Sfx), then (if hSndOn) writes the
; dead registers 6/7 and outputs Ch2, Ch3 and either Sfx (while wSfxId != 0) or Ch1 to CH1.
SndUpdate:
	ld a, $FF
	ldh [rNR50], a
	ld a, $8F
	ldh [rNR52], a
	ld hl, wCh1
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	ldh a, [hSndOn]
	and a
	ret z
	call WriteReg67
	ld h, $C2
	call OutputChannel
	call OutputChannel
	ld h, $C1
	ld a, [wSfxId]
	and a
	jp z, OutputChannel
	ld h, $C4

; OutputChannel (h = page): write freq lo/hi and volume through WriteReg using
; the register indices in fields $06/$08/$0A. Volume = (vol - vol table) (or
; field $37 if nonzero), minus field $38, minus hSfxAtten (Sfx page while
; wSfxLockedVol = 0) or hMusAtten (others). Advances h.
OutputChannel:
	ld l, $06
	ld a, [hl]
	inc l
	ld c, [hl]
	call WriteReg
	inc l
	ld a, [hl]
	inc l
	ld c, [hl]
	call WriteReg
	inc l
	ld e, [hl]
	inc l
	ld a, [hl]
	call ApplyVolTable
	ld c, a
	ld l, $37
	ld a, [hl]
	and a
	jr z, L5187
	ld c, a
L5187:
	ld a, c
	ld l, $2F
	ld a, [hl]
	and a
	jp z, Output_Atten
	ld a, c
	cp $0F
	jp nz, Output_Atten
	ld a, $10                          ; field $2F is never set: dead
	jp L51CB
Output_Atten:
	ld l, $38
	ld a, [hl]
	ld l, a
	ld a, c
	sub l
	jp nc, L51A4
	xor a
L51A4:
	push af
	ld a, h
	cp $C4
	jp nz, L51BD
	ld a, [wSfxLockedVol]
	and a
	jp nz, L51BD
	push af
	ldh a, [hSfxAtten]
	ld c, a
	ldh a, [hMusAtten]
	ld b, a
	pop af
	jp L51C5
L51BD:
	push af
	ldh a, [hMusAtten]
	ld c, a
	ldh a, [hShNR51]
	ld b, a
	pop af
L51C5:
	pop af
	sub c
	jp nc, L51CB
	xor a
L51CB:
	ld c, a
	ld a, e
	call WriteReg
	inc h
	ret

; StopAll: hSndOn = 0, reset all four pages, hTranspose = 0, unlock SFX,
; NR51 = 0. Also the game's sound init and the STOP_ALL command.
StopAll:
	push af
	push de
	push bc
	push hl
	xor a
	ldh [hSndOn], a
	ld a, $07
	ld c, $BF
	push bc
	call WriteReg
	pop bc
	ld a, c
	ldh [hMask], a
	ld h, $C1
	call ResetChannelMask
	inc h
	call ResetChannelMask
	inc h
	call ResetChannelMask
	inc h
	call ResetChannelMask
	xor a
	ldh [hTranspose], a
	ldh [hSfxLock], a
	xor a
	ldh [rNR51], a
	ldh [hShNR51], a
	pop hl
	pop bc
	pop de
	pop af
	ret
ResetChannelMask:
	call GetMask
ResetChannel:
	xor a
	ld l, $30
	ld [hl], a
	ld l, $0B
	ld [hl], a
	ld l, $2E
	ld [hl], a
	ld l, $34
	ld [hl], a
	ld l, $35
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld l, $38
	ld [hl], a
	ld l, $2F
	ld [hl], a
	ld l, $16
	ld [hl], $01
	inc l
	ld [hli], a
	ld [hl], a
	ld l, $04
	ld [hl], a
	ld l, $15
	ld [hl], a
	ld l, $05
	ld [hl], $01
	ret
WriteReg67:
	ldh a, [hReg6]
	ld c, a
	ld a, $06
	call WriteReg
	ldh a, [hMask]
	ld c, a
	ld a, $07
	call WriteReg
	ret

; ChannelTick (h = page): skipped while field $30 = 0.
ChannelTick:
	ld l, $30
	ld a, [hl]
	and a
	ret z
	ld l, $04
	bit 4, [hl]
	jr z, L524E                        ; jr z, +0: dead test of flag bit 4
L524E:
	ld l, $20
	ldh a, [hMask]
	and [hl]
	jp nz, L525B
	ld l, $07
	ld a, [hl]
	ldh [hReg6], a
L525B:
	ld l, $02
	ld e, [hl]
	inc l
	ld d, [hl]
	call DoArp
	ld l, $05
	dec [hl]
	jp z, ReadStream
	call DoGlide
	call CheckRelease
	call DoEnvelope
	call DoSlide
	call DoBend
	call DoVibrato
	ld l, $04
	bit 5, [hl]
	ret z
	ld a, [wCh1Vol]
	ld l, $0B
	ld [hl], a
	and $07
	ld c, a
	ld l, $07
	ld a, [wCh1FreqLo]
	add a, c
	ld [hl], a
	ld a, [wCh1FreqHi]
	ld l, $09
	ld [hl], a
	ret nc
	inc [hl]
	ret

; ReadStream (de = stream): process bytes until a note or a "wait"
; command ends the tick. hInInstr = $C9 while an instrument macro runs (then
; nothing here may run; the ret z is never taken in practice).
ReadStream:
	nop                                ; nop
	ldh a, [hInInstr]
	cp $C9
	ret z
	ld a, [de]
	inc de
	cp $60
	jp nc, StreamCommand
	ld l, $2E
	bit 0, [hl]
	call nz, ArpRestart
	ld l, $39
	bit 0, [hl]
	jp z, L52C3
	ld [hl], $00
	push af
	push hl
	ld hl, wSfxId
	call StopSfx
	pop hl
	call Cmd_MaskA
	pop af
L52C3:
	ld l, $3C
	bit 0, [hl]
	jp z, L52D8
	ld [hl], $00
	push de
	ld e, $31
	ld l, $3A
	ld d, h
	rst $20
	rst $20
	inc l
	inc e
	rst $20
	pop de
L52D8:
	push af
	ld a, h
	cp $C1
	jp nz, L52E3
	ld a, $01
	ldh [hCh1NoteFlag], a              ; hCh1NoteFlag = 1 on every Ch1 note (read by the game)
L52E3:
	pop af
	ld l, $0C
	ld [hl], a
	ld l, $33
	ld [hl], $00
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	call SetNoteFreq
	ld l, $14
	ld a, [hl]
	ld l, $0B
	ld [hl], a
	ld l, $0D
	ld a, [hl]
	ld l, $05
	ld [hl], a
	ld l, $18
	ld [hl], $00
	ld l, $2D
	ld a, [hl]
	srl a
	dec l
	ld [hl], a
	ld l, $0E
	call SplitNibbles
	inc l
SplitNibbles:
	ld a, [hl]
	ld c, a
	and $0F
	inc l
	ld [hl], a
	ld a, c
	swap a
	and $0F
	inc l
	ld [hl], a
	ret
ArpRestart:
	ld l, $23
	ld [hl], $00
	ld l, $2E
	ld [hl], $00
	ret

; Command ranges: $DF+ length, $CF+ vol/env, $BF+ volume, $B0+ arpeggio,
; $9A+ play SFX, $80+ instrument, $60-$7F table.
StreamCommand:
	cp $DF
	jp nc, Cmd_Len
	cp $CF
	jp nc, Cmd_VolEnv
	cp $BF
	jp nc, Cmd_Vol
	cp $B0
	jp nc, Cmd_Arp
	cp $9A
	jp nc, Cmd_PlaySfx
	cp $80
	jp nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	add a, LOW(CmdTable)
	ld c, a
	adc a, HIGH(CmdTable)
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	call CallBC                        ; call the handler at bc
	jp ReadStream
Cmd_Len:
	sub $DE
	ld l, $0D
	ld [hl], a
	jp ReadStream
Cmd_Vol:
	sub $BF
	ld l, $14
	ld [hl], a
	jp ReadStream
Cmd_VolEnv:
	sub $CF
	ld l, $14
	ld [hl], a
	rst $28
	ld e, $0E
	rst $20
	ld e, $11
	rst $20
	rst $28
	ld a, [de]
	swap a
	and $0F
	ld l, $19
	ld [hli], a
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, $1B
	ld [hli], a
	ld [hl], a
	inc de
	jp ReadStream
Cmd_Arp:
	sub $B0
	add a, a
	add a, LOW(ArpTable)
	ld c, a
	adc a, HIGH(ArpTable)
	sub c
	ld b, a
	ld a, [bc]
	ld l, $21
	ld [hli], a
	inc bc
	ld a, [bc]
	ld [hl], a
	ld l, $23
	ld [hl], $00
	ld l, $04
	set 0, [hl]
	jp ReadStream
CheckRelease:
	ld l, $16
	ld a, [hl]
	ld l, $05
	cp [hl]
	ret nz
	ld a, [de]
	cp $6B
	ret z
	ld l, $18
	ld [hl], $01
	ld l, $04
	res 1, [hl]
	ret
Cmd_End:
	pop af
StopSfx:
	ldh a, [hMaskSaved]
	ldh [hMask], a
	xor a
	ldh [hSfxLock], a
	call ResetChannel
	jp WriteReg67
Cmd_GlideOff:
	ld l, $15
	ld [hl], $00
	ret
Cmd_BendOff:
	ld l, $04
	res 2, [hl]
	ret
Cmd_MaskA:
	call GetMask
	ld l, $1F
L53DA:
	ld a, [hl]
L53DB:
	cpl
	and c
	ld c, a
	ld a, h
	cp $C3
	jp z, L53E8
L53E4:
	ld a, c
	ldh [hMask], a
	ret
L53E8:
	ld a, [wSfxId]
	and a
	jp z, L53E4
	ld a, c
	ldh [hMaskSaved], a
	ret
Cmd_MaskB:
	call GetMask
	ld l, $20
	jp L53DA
Cmd_MaskAB:
	call GetMask
	ld l, $1F
	ld a, [hli]
	or [hl]
	jp L53DB
Cmd_Rest:
	ld l, $0B
	ld [hl], $00
	ld l, $39
	ld a, [hl]
	and a
	jp z, Cmd_Wait
	ld [hl], $00
	push hl
	ld h, $C4
	call StopSfx
	pop hl
Cmd_Wait:
	pop af
	ld l, $0D
	ld a, [hl]
	ld l, $05
	ld [hl], a
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
GetMask:
	ldh a, [hMask]
	ld l, $1F
	or [hl]
	inc l
	or [hl]
	ld c, a
	ret
Cmd_Glide:
	ld l, $15
	ld a, [de]
	inc de
	ld [hl], a
	ret
DoGlide:
	ld l, $15
	ld a, [hl]
	and a
	ret z
	ld l, $0C
	add a, [hl]
	ld [hl], a
	jp SetNoteFreq

; DoArp: add the next arpeggio table entry to the note. $73 restarts the table,
; $FF holds (field $2E = 1, offset 0).
DoArp:
	ld l, $04
	bit 0, [hl]
	ret z
L5445:
	ld l, $21
	ld a, [hli]
	ld b, [hl]
	inc l
	add a, [hl]
	ld c, a
	jp nc, L5450
	inc b
L5450:
	ld a, [bc]
	cp $73
	jp nz, L545B
	ld [hl], $01
	jp L5445
L545B:
	cp $FF
	jr nz, L5467
	ld l, $2E
	ld [hl], $01
	xor a
	jp L5468
L5467:
	inc [hl]
L5468:
	ld l, $0C
	add a, [hl]

; SetNoteFreq (a = note): index = note - 12 (- 36 more on Ch3) + hTranspose
; (the SFX page subtracts hTranspose again) -> PeriodTable. With BEND active
; the start offset (fields $27/$28) is added and the slide count restarts.
SetNoteFreq:
	add a, $F4
	ld c, a
	ld a, h
	cp $C3
	jr nz, L5477
	ld a, c
	add a, $DC
	ld c, a
L5477:
	ldh a, [hTranspose]
	add a, c
	push af
	ld a, h
	cp $C4
	jp nz, L5489
	ldh a, [hTranspose]
	ld c, a
	pop af
	sub c
	jp L548A
L5489:
	pop af
L548A:
	add a, a
	add a, LOW(PeriodTable)
	ld c, a
	adc a, HIGH(PeriodTable)
	sub c
	ld b, a
	push de
	ld a, [bc]
	inc bc
	ld e, a
	ld a, [bc]
	ld d, a
	ld l, $07
	ld [hl], e
	inc l
	inc l
	ld [hl], d
	pop de
	ld l, $04
	bit 2, [hl]
	ret z
	push de
	ld l, $27
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, $07
	ld c, [hl]
	ld l, $09
	ld b, [hl]
	rst $28
	add hl, bc
	rst $28
	ld [hl], d
	ld l, $07
	ld [hl], e
	ld l, $29
	ld a, [hl]
	ld l, $26
	ld [hl], a
	pop de
	ret
CmdTable:
	dw Cmd_Glide
	dw Cmd_Release
	dw Cmd_ArpOff
	dw Cmd_Slide
	dw Cmd_Bend
	dw Cmd_BendOff
	dw Cmd_Vibrato
	dw Cmd_VibratoOff
	dw Cmd_MaskA
	dw Cmd_MaskB
	dw Cmd_MaskAB
	dw Cmd_Wait
	dw Cmd_Rest
	dw StopAll
	dw Cmd_ChorusOn
	dw Cmd_ChorusOff
	dw Cmd_End
	dw Cmd_GlideOff
	dw Cmd_Transpose
	dw Cmd_Next
	dw Cmd_OrderJump
	dw Cmd_Atten
	dw Cmd_Length
	dw Cmd_NoteOff
	dw Cmd_NoiseHit1
	dw Cmd_PanC
	dw Cmd_PanR
	dw Cmd_PanL
	dw Cmd_Duty50
	dw Cmd_Duty75
	dw Cmd_Duty12
	dw Cmd_NoiseHit2
Cmd_Duty50:
	ld c, $80
SetDuty:
	ld a, h
	cp $C2
	jr z, L550F
	cp $C1
	ret nz
	ld a, c
	ldh [hShNR11], a
	ldh [rNR11], a
	ret
L550F:
	ld a, c
	ldh [hShNR21], a
	ldh [rNR21], a
	ret
Cmd_Duty75:
	ld c, $C0
	jr SetDuty
Cmd_Duty12:
	ld c, $00
	jr SetDuty
Cmd_PanC:
	ld bc, $FF11
SetPan:
	ld a, h
	cp $C1
	jr z, L552D
	cp $C2
	jr z, L5536
	cp $C3
	jr z, L5540
L552D:
	ldh a, [hShNR51]
	or c
	and b
L5531:
	ldh [hShNR51], a
	ldh [rNR51], a
	ret
L5536:
	rlc b
	rlc c
	ldh a, [hShNR51]
	or c
	and b
	jr L5531
L5540:
	rlc b
	rlc b
	rlc c
	rlc c
	ldh a, [hShNR51]
	or c
	and b
	jr L5531
Cmd_PanR:
	ld bc, $EF01
	jr SetPan
Cmd_PanL:
	ld bc, $FE10
	jr SetPan

; Cmd_Instrument ($80-$99): runs the instrument macro (commands only, no
; notes) until $70 or $73. Instruments 2 and 3 ($82/$83) also fire a noise hit.
Cmd_Instrument:
	push de
	push hl
	cp $82
	call z, NoiseHitInstr
	cp $83
	call z, NoiseHitInstr
	ld l, $04
	res 3, [hl]
	res 0, [hl]
	ld l, $15
	ld [hl], $00
	ld l, $34
	ld [hl], $00
	ld l, $3D
	ld [hl], $00
	sub $7F
	add a, a
	ld hl, InstrTable - 2
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld a, $C9
	ldh [hInInstr], a
InstrLoop:
	ld a, [de]
	inc de
	cp $70
	jp z, InstrDone
	cp $73
	jp z, InstrDone
	call InstrCommand
	jp InstrLoop
InstrCommand:
	cp $DF
	jp nc, Cmd_Len
	cp $CF
	jp nc, Cmd_VolEnv
	cp $BF
	jp nc, Cmd_Vol
	cp $B0
	jp nc, Cmd_Arp
	sub $60
	add a, a
	ld c, a
	add a, LOW(CmdTable)
	ld c, a
	adc a, HIGH(CmdTable)
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	call CallBC
	ret
InstrDone:
	xor a
	ldh [hInInstr], a
	pop de
	jp ReadStream

; Dead bytes (sub $9A), not reachable.
Orphan_55CB:
	db $D6, $9A

; Cmd_NoteOff ($77): save the vol-table pointer/flag, point it to
; NoteOffVolTable (decay), and wait. The next note restores it.
Cmd_NoteOff:
	push de
	ld l, $31
	ld e, $3A
	ld d, h
	rst $20
	rst $20
	inc l
	inc e
	rst $20
	ld l, $31
	ld [hl], LOW(NoteOffVolTable)
	inc l
	ld [hl], HIGH(NoteOffVolTable)
	ld l, $33
	ld [hl], $00
	ld l, $3C
	ld [hl], $01
	ld l, $34
	ld [hl], $01
	pop de
	jp Cmd_Wait
NoteOffVolTable:
	db $00, $01, $03, $04, $04, $04, $05, $05, $05, $06, $06, $06, $07, $07, $07, $08
	db $08, $08, $09, $09, $09, $0B, $0B, $0B, $0C, $0D, $0F, $10, $FF

; Dead handler, not in CmdTable: pop af / res 4,[field $04] / ret.
Orphan_560C:
	db $F1, $2E, $04, $CB, $A6, $C9
Cmd_Length:
	ld a, [de]
	ld l, $0D
	ld [hl], a
	inc de
	ret
Cmd_Atten:
	ld a, [de]
	ld l, $38
	ld [hl], a
	inc de
	ret
Cmd_Transpose:
	ld a, [de]
	ldh [hTranspose], a
	inc de
	ret

; Cmd_PlaySfx ($9A-$AF): start sound (byte - $9A) on the SFX page, mark this
; channel (field $39) so that its next note stops the SFX again, then wait.
Cmd_PlaySfx:
	sub $9A
	ld l, $39
	ld [hl], $01
	push hl
	push de
	call PlaySound
	pop de
	pop hl
	jp Cmd_Wait
Cmd_Vibrato:
	rst $28
	ld e, $2A
	rst $20
	rst $20
	ld a, [hl]
	rst $20
	ld [de], a
	rst $28
	ld l, $04
	set 3, [hl]
	set 6, [hl]
	ret
Cmd_Release:
	ld a, [de]
	inc de
	ld l, $16
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, $1D
	ld [hli], a
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, $17
	ld [hl], a
	inc de
	ret
Cmd_ArpOff:
	ld l, $04
	res 0, [hl]
	ld l, $2E
	xor a
	ld [hl], a
	ld l, $34
	ld [hl], a
	ret
Cmd_Slide:
	rst $28
	ld e, $24
	rst $20
	rst $20
	rst $20
	rst $28
	ld l, $04
	set 1, [hl]
	ret
Cmd_Bend:
	rst $28
	ld e, $27
	rst $20
	rst $20
	ld e, $24
	rst $20
	rst $20
	ld e, $29
	rst $20
	rst $28
	ld l, $04
	set 2, [hl]
	ret
Cmd_ChorusOn:
	ld l, $04
	set 5, [hl]
	ret
Cmd_ChorusOff:
	ld l, $04
	res 5, [hl]
	ret
Cmd_VibratoOff:
	ld l, $04
	res 3, [hl]
	ret
DoBend:
	ld l, $04
	bit 2, [hl]
	jp nz, SlideStep
	ret
DoSlide:
	ld l, $04
	bit 1, [hl]
	ret z
SlideStep:
	ld l, $26
	dec [hl]
	bit 7, [hl]
	jp nz, L57AB
	ld l, $25
	bit 7, [hl]
	jp nz, L56BD
	ld l, $24
	ld a, [hl]
	ld l, $07
	add a, [hl]
	ld [hl], a
	ld l, $25
	ld a, [hl]
	ld l, $09
	adc a, [hl]
	ld [hl], a
	ret
L56BD:
	ld l, $07
	ld a, [hl]
	ld l, $24
	sub [hl]
	ld l, $07
	ld [hl], a
	ld l, $25
	ld c, [hl]
	res 7, c
	ld l, $09
	ld a, [hl]
	sbc a, c
	ld [hl], a
	ret
DoVibrato:
	ld l, $04
	bit 3, [hl]
	ret z
	dec de
	ld a, [de]
	inc de
	cp $6B
	jp z, L56E8
	ld l, $0D
	ld a, [hl]
	ld l, $2A
	sub [hl]
	ld l, $05
	cp [hl]
	ret c
L56E8:
	ld l, $04
	bit 6, [hl]
	jp z, L5709
	ld l, $2C
	dec [hl]
	jp nz, L56FD
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	res 6, [hl]
	ret
L56FD:
	ld l, $2B
	ld a, [hl]
	ld l, $07
	add a, [hl]
	ld [hl], a
	ret nc
	ld l, $09
	inc [hl]
	ret
L5709:
	ld l, $2C
	dec [hl]
	jp nz, L5717
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	set 6, [hl]
	ret
L5717:
	ld l, $07
	ld a, [hl]
	ld l, $2B
	sub [hl]
	ld l, $07
	ld [hl], a
	ret nc
	ld l, $09
	dec [hl]
	ret

; ApplyVolTable: if field $34 is set, read the next byte of the volume table
; (fields $31/$32, index $33): $FF holds, $73 restarts. Returns vol - entry
; (floor 0) in a.
ApplyVolTable:
	ld l, $34
	bit 0, [hl]
	ret z
L572A:
	ld l, $31
	ld a, [hli]
	ld b, [hl]
	inc l
	add a, [hl]
	ld c, a
	jp nc, L5735
	inc b
L5735:
	inc [hl]
	ld a, [bc]
	cp $FF
	jp nz, L573F
	dec [hl]
	dec bc
	ld a, [bc]
L573F:
	cp $73
	jp nz, L5749
	ld [hl], $00
	jp L572A
L5749:
	ld l, $0B
	ld c, a
	ld a, [hl]
	sub c
	ret nc
	xor a
	ret

; DoEnvelope: attack (fields $0F/$10/$19/$1A), then decay ($12/$13/$1B/$1C),
; then release ($18 set by CheckRelease: $17/$1D/$1E).
DoEnvelope:
	ld l, $0F
	ld a, [hl]
	or a
	jp z, L5772
	ld l, $19
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $0F
	dec [hl]
	inc l
	ld a, [hl]
	ld l, $0B
	add a, [hl]
	cp $0F
	jp nc, L576E
L576C:
	ld [hl], a
	ret
L576E:
	ld a, $0F
	jr L576C
L5772:
	ld l, $12
	ld a, [hl]
	or a
	jp z, L5791
	ld l, $1B
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $12
	dec [hl]
	ld l, $0B
	ld a, [hl]
	ld l, $13
	sub [hl]
	jp nc, L578D
	xor a
L578D:
	ld l, $0B
	ld [hl], a
	ret
L5791:
	ld l, $18
	ld a, [hl]
	or a
	ret z
	ld l, $1D
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $0B
	ld a, [hl]
	ld l, $17
	sub [hl]
	jp nc, L57A7
	xor a
L57A7:
	ld l, $0B
	ld [hl], a
	ret
L57AB:
	inc [hl]
	ret

; Period table: 70 entries, C2 (65.4 Hz) .. A7. The last entries are not monotonic
; ($07E6 is followed by $07E2).
PeriodTable:
	dw $002D
	dw $009D
	dw $0107
	dw $016B
	dw $01CA
	dw $0223
	dw $0277
	dw $02C7
	dw $0312
	dw $0359
	dw $039C
	dw $03DB
	dw $0417
	dw $044F
	dw $0484
	dw $04B6
	dw $04E5
	dw $0512
	dw $053C
	dw $0564
	dw $0589
	dw $05AD
	dw $05CE
	dw $05EE
	dw $060C
	dw $0628
	dw $0642
	dw $065B
	dw $0673
	dw $0689
	dw $069E
	dw $06B2
	dw $06C5
	dw $06D7
	dw $06E7
	dw $06F7
	dw $0706
	dw $0714
	dw $0721
	dw $072E
	dw $073A
	dw $0745
	dw $074F
	dw $0759
	dw $0763
	dw $076C
	dw $0774
	dw $077C
	dw $0783
	dw $078A
	dw $0791
	dw $0797
	dw $079D
	dw $07A3
	dw $07A8
	dw $07AD
	dw $07B2
	dw $07B6
	dw $07BA
	dw $07BE
	dw $07C2
	dw $07C5
	dw $07C9
	dw $07CC
	dw $07CF
	dw $07D2
	dw $07D4
	dw $07D7
	dw $07D9
	dw $07DB
	dw $07DD
	dw $07DF
	dw $07E1
	dw $07E3
	dw $07E5
	dw $07E6
	dw $07E2
	dw $07E9
	dw $07EA
	dw $07EC
	dw $07ED

; StartMusicChN (de = order list): reset the page, set field $30, read the first
; pattern pointer and store the order position.
StartMusicCh1:
	ld h, $C1
	jp StartMusicCh
StartMusicCh2:
	ld h, $C2
	jp StartMusicCh
StartMusicCh3:
	ld h, $C3
StartMusicCh:
	call ResetChannelMask
	and a
	jp nz, L5864
	ld a, $01
L5864:
	ld l, $30
	ld [hl], a
	ld l, $02
	ld a, [de]
	ld [hl], a
	inc de
	ld a, [de]
	inc hl
	ld [hl], a
	ld l, $00
	inc de
	ld [hl], e
	inc l
	ld [hl], d
	ret
Cmd_OrderJump:
	ld l, $00
	rst $28
	rst $20
	rst $20
	rst $28

; Cmd_Next ($73): next pattern from the order list. A 0 word ends the list; the
; next word is the new order position (executed as ORDER_JUMP).
Cmd_Next:
	ld l, $00
	ld c, [hl]
	inc l
	ld b, [hl]
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	inc bc
	ld d, a
	or e
	jp z, Next_OrderEnd
	ld [hl], b
	dec l
	ld [hl], c
	inc l
	inc l
	ld [hl], e
	inc l
	ld [hl], d
	ret
Next_OrderEnd:
	ld d, b
	ld e, c
	pop bc
	ld a, $74
	jp StreamCommand
NoiseHitInstr:
	push af
	ld a, $F1
	ldh [rNR42], a
	ld a, $60
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	pop af
	ret
Cmd_NoiseHit1:
	push af
	ld a, $F1
	ldh [rNR42], a
	ld a, $0A
	ldh [rNR43], a
	ld a, $39
	ldh [rNR41], a
	ld a, $C0
	ldh [rNR44], a
	pop af
	ret
Cmd_NoiseHit2:
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret

; WriteReg (a = index 0-12, c = value): through RegHandlerTable; indices >= 13 are ignored.
; Freq-hi and volume writes are skipped when the shadow already holds the value;
; when they do happen they retrigger the channel.
WriteReg:
	push hl
	push de
	push bc
	push af
	cp $0D
	jr nc, L58DD
	add a, a
	add a, LOW(RegHandlerTable)
	ld l, a
	adc a, HIGH(RegHandlerTable)
	sub l
	ld h, a
	rst $08
	rst $10
L58DD:
	pop af
	pop bc
	pop de
	pop hl
	ret
RegHandlerTable:
	dw Reg_NR13
	dw Reg_NR14
	dw Reg_NR23
	dw Reg_NR24
	dw Reg_NR33
	dw Reg_NR34
	dw Reg_None
	dw Reg_None
	dw Reg_NR12
	dw Reg_NR22
	dw Reg_NR32
	dw Reg_None2
	dw Reg_None2
	dw Reg_None2
Reg_NR13:
	ld a, c
	ldh [rNR13], a
	ret
Reg_NR14:
	ld a, c
	and $07
	ld c, a
	ldh a, [hShNR14]
	cp c
	jr z, L5912
	ld a, c
	ldh [hShNR14], a
	or $80
	ldh [rNR14], a
L5912:
	ret
Reg_NR23:
	ld a, c
	ldh [rNR23], a
	ret
Reg_NR24:
	ld a, c
	and $07
	ld c, a
	ldh a, [hShNR24]
	cp c
	jr z, L5927
	ld a, c
	ldh [hShNR24], a
	or $80
	ldh [rNR24], a
L5927:
	ret
Reg_NR33:
	ld a, c
	ldh [rNR33], a
	ret
Reg_NR34:
	ld a, c
	and $07
	ld c, a
	ldh a, [hShNR34]
	cp c
	jr z, L593C
	ld a, c
	ldh [hShNR34], a
	or $80
	ldh [rNR34], a
L593C:
	ret
Reg_None:
	ret
Reg_NR12:
	ld a, c
	and $0F
	ld c, a
	ldh a, [hShNR12]
	cp c
	jr z, L5954
	ld a, c
	ldh [hShNR12], a
	swap a
	ldh [rNR12], a
	ldh a, [hShNR14]
	or $80
	ldh [rNR14], a
L5954:
	ret
Reg_NR22:
	ld a, c
	and $0F
	ld c, a
	ldh a, [hShNR22]
	cp c
	jr z, L596B
	ld a, c
	ldh [hShNR22], a
	swap a
	ldh [rNR22], a
	ldh a, [hShNR24]
	or $80
	ldh [rNR24], a
L596B:
	ret
Reg_NR32:
	ld a, c
	and $0F
	add a, LOW(Ch3VolTable)
	ld l, a
	adc a, HIGH(Ch3VolTable)
	sub l
	ld h, a
	ld c, [hl]
	ldh a, [hShNR32]
	cp c
	jr z, L5987
	ld a, c
	ldh [hShNR32], a
	ldh [rNR32], a
	ldh a, [hShNR34]
	or $80
	ldh [rNR34], a
L5987:
	ret
Ch3VolTable:
	db $00, $00, $00, $00, $60, $60, $60, $60, $40, $40, $40, $40, $20, $20, $20, $20
Reg_None2:
	ret

; Save IE and disable all interrupts / restore IE (used while starting the title music).
DisableInts:
	ldh a, [rIE]
	ldh [hSavedIE], a
	xor a
	ldh [rIE], a
	ret
RestoreInts:
	ldh a, [hSavedIE]
	ldh [rIE], a
	ret

; PlayTitleMusic: called by the game (title screen).
PlayTitleMusic:
	push de
	push bc
	push hl
	call DisableInts
	call StopAll
	ld de, Title_Ch1
	call StartMusicCh1
	ld de, Title_Ch3
	call StartMusicCh3
	ld de, Title_Ch2
	call StartMusicCh2
	ld a, $FF
	ldh [rNR51], a
	ldh [hShNR51], a
	call RestoreInts
	pop hl
	pop bc
	pop de
	ret
Title_Ch1:
	dw Pat_5A58
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5AA8
	dw Pat_5ADB
	dw Pat_5AA8
	dw Pat_5AA8
	dw Pat_5ADB
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5A75
	dw Pat_5AA8
	dw Pat_5AA8
	dw Pat_5B12
	dw Pat_5AA8
	dw Pat_5AA8
	dw Pat_5B12
	ORDER_LOOP Title_Ch1
Title_Ch3:
	dw Pat_5C85
	dw Pat_5C85
	dw Pat_5B34
	dw Pat_5B34
	dw Pat_5B34
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5B34
	dw Pat_5B34
	dw Pat_5B34
	dw Pat_5B34
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	dw Pat_5BC7
	ORDER_LOOP Title_Ch3
Title_Ch2:
	dw Pat_5C5A
	dw Pat_5C5A
	dw Pat_5CAA
	dw Pat_5CAA
	dw Pat_5D25
	dw Pat_5CE6
	dw Pat_5D8B
	dw Pat_5D8B
	dw Pat_5DD7
	dw Pat_5DD7
	dw Pat_5D5B
	dw Pat_5CAA
	dw Pat_5CAA
	dw Pat_5D25
	dw Pat_5CE6
	dw Pat_5D8B
	dw Pat_5D8B
	dw Pat_5E22
	dw Pat_5DD7
	dw Pat_5DD7
	dw Pat_5E22
	ORDER_LOOP Title_Ch2
Pat_5A58:
	LEN 7
	PAN_C
	INSTR 13
	NOTE C_, 3
	LENGTH $69
	WAIT
	LEN 7
	NOTE G_, 2
	LENGTH $69
	WAIT
	LEN 7
	NOTE A_, 2
	LENGTH $69
	WAIT
	LEN 7
	NOTE F_, 2
	LENGTH $31
	WAIT
	LEN 7
	NOTE G_, 2
	LENGTH $31
	WAIT
	LEN 7
	NEXT
Pat_5A75:
	LEN 14
	INSTR 11
	NOTE C_, 2
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NEXT
Pat_5AA8:
	LEN 14
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	NEXT
Pat_5ADB:
	TRANSPOSE $02
	LEN 14
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE C_, 2
	WAIT
	INSTR 3
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	TRANSPOSE $00
	NEXT
Pat_5B12:
	LEN 7
	INSTR 25
	NOTE C_, 2
	LENGTH $FC
	WAIT
	LENGTH $4E
	WAIT
	PAN_L
	LEN 7
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	LEN 2
	NOTE G_, 5
	LEN 5
	NOTE A_, 5
	LEN 7
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	LEN 6
	WAIT
	PAN_C
	NEXT
Pat_5B34:
	LEN 7
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE B_, 5
	INSTR 5
	NOTE B_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE B_, 5
	INSTR 5
	NOTE B_, 6
	PAN_C
	NEXT
Pat_5BC7:
	LEN 7
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_R
	NOTE C_, 6
	INSTR 5
	NOTE C_, 7
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	PAN_L
	NOTE A_, 5
	INSTR 5
	NOTE A_, 6
	INSTR 15
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	PAN_R
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	INSTR 15
	NOTE D_, 5
	INSTR 5
	NOTE D_, 6
	INSTR 15
	PAN_L
	NOTE E_, 5
	INSTR 5
	NOTE E_, 6
	INSTR 15
	NOTE G_, 5
	INSTR 5
	NOTE G_, 6
	PAN_C
	NEXT
Pat_5C5A:
	LEN 8
	INSTR 25
	PAN_R
	NOTE C_, 6
	LEN 7
	WAIT
	LEN 14
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 7
	NOTE G_, 5
	LEN 6
	WAIT
	PAN_C
	NEXT
Pat_5C85:
	LEN 14
	INSTR 25
	PAN_L
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	PAN_C
	NEXT
Pat_5CAA:
	LEN 14
	REST
	WAIT
	LEN 7
	INSTR 7
	NOTE C_, 5
	NOTE_OFF
	NOTE C_, 5
	WAIT
	WAIT
	NOTE_OFF
	NOTE B_, 4
	NOTE_OFF
	NOTE A_, 4
	WAIT
	WAIT
	NOTE_OFF
	NOTE G_, 4
	LENGTH $31
	WAIT
	LEN 7
	NOTE D_, 4
	NOTE_OFF
	NOTE E_, 4
	NOTE_OFF
	NOTE F_, 4
	WAIT
	WAIT
	NOTE_OFF
	NOTE E_, 4
	WAIT
	WAIT
	NOTE_OFF
	NOTE C_, 4
	NOTE_OFF
	NOTE C_, 4
	LENGTH $23
	WAIT
	LEN 7
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE_OFF
	NOTE C_, 4
	NOTE_OFF
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE_OFF
	NOTE D_, 4
	LENGTH $2A
	WAIT
	LEN 7
	NOTE_OFF
	NEXT
Pat_5CE6:
	LEN 28
	NOTE C_, 7
	LEN 7
	INSTR 7
	NOTE C_, 6
	NOTE_OFF
	NOTE C_, 6
	WAIT
	WAIT
	NOTE_OFF
	NOTE D_, 6
	NOTE_OFF
	NOTE E_, 6
	WAIT
	NOTE F_, 6
	NOTE_OFF
	LEN 28
	NOTE G_, 6
	NOTE D_, 6
	LEN 7
	NOTE D_, 6
	NOTE_OFF
	NOTE E_, 6
	NOTE_OFF
	LEN 28
	NOTE F_, 6
	NOTE E_, 6
	LEN 7
	NOTE C_, 6
	NOTE_OFF
	LEN 14
	NOTE C_, 6
	WAIT
	NOTE B_, 5
	NOTE C_, 6
	WAIT
	WAIT
	INSTR 2
	PAN_R
	NOTE C_, 4
	INSTR 2
	PAN_L
	NOTE C_, 4
	WAIT
	INSTR 2
	PAN_R
	NOTE F_, 4
	INSTR 2
	PAN_L
	NOTE C_, 4
	LEN 7
	INSTR 2
	PAN_R
	NOTE C_, 4
	INSTR 2
	PAN_L
	NOTE C_, 4
	INSTR 2
	PAN_R
	NOTE C_, 4
	WAIT
	PAN_C
	NEXT
Pat_5D25:
	LEN 28
	WAIT
	LEN 7
	INSTR 7
	NOTE C_, 6
	NOTE_OFF
	NOTE C_, 6
	WAIT
	WAIT
	NOTE_OFF
	NOTE D_, 6
	NOTE_OFF
	NOTE E_, 6
	WAIT
	NOTE F_, 6
	NOTE_OFF
	LEN 28
	NOTE G_, 6
	NOTE D_, 6
	LEN 7
	NOTE D_, 6
	NOTE_OFF
	NOTE E_, 6
	NOTE_OFF
	LEN 28
	NOTE F_, 6
	NOTE E_, 6
	LEN 7
	NOTE C_, 6
	NOTE_OFF
	LEN 14
	NOTE C_, 6
	WAIT
	NOTE B_, 5
	NOTE C_, 6
	WAIT
	LEN 7
	NOTE C_, 7
	NOTE_OFF
	NOTE G_, 6
	NOTE_OFF
	NOTE A_, 6
	NOTE_OFF
	NOTE E_, 6
	NOTE_OFF
	NOTE B_, 6
	NOTE_OFF
	NOTE G_, 6
	NOTE_OFF
	NOTE A_, 6
	NOTE_OFF
	NOTE B_, 6
	NOTE_OFF
	NEXT
Pat_5D5B:
	LEN 7
	INSTR 10
	NOTE C_, 4
	LENGTH $69
	WAIT
	LEN 7
	INSTR 18
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	WAIT
	INSTR 10
	NOTE C_, 5
	LENGTH $69
	WAIT
	LEN 7
	INSTR 18
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	WAIT
	NEXT
Pat_5D8B:
	LEN 14
	INSTR 8
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	LEN 7
	WAIT
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	NEXT

; Pattern that no order list uses.
Pat_5DB1_unused:
	LEN 14
	INSTR 8
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	LEN 7
	WAIT
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	WAIT
	NEXT
Pat_5DD7:
	LEN 14
	INSTR 6
	NOTE Fsh, 5
	NOTE_OFF
	INSTR 15
	NOTE Fsh, 4
	LEN 7
	WAIT
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 6
	NOTE G_, 5
	NOTE E_, 5
	INSTR 15
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	INSTR 2
	PAN_R
	NOTE C_, 4
	INSTR 2
	PAN_L
	NOTE C_, 4
	LEN 7
	PAN_C
	INSTR 6
	NOTE Fsh, 5
	NOTE_OFF
	INSTR 15
	NOTE Fsh, 4
	WAIT
	INSTR 6
	NOTE Fsh, 5
	NOTE_OFF
	INSTR 15
	NOTE Fsh, 4
	WAIT
	INSTR 6
	NOTE Fsh, 5
	NOTE_OFF
	LEN 14
	INSTR 15
	NOTE Fsh, 4
	INSTR 6
	NOTE G_, 5
	NOTE E_, 5
	INSTR 15
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	INSTR 2
	PAN_R
	NOTE F_, 4
	INSTR 2
	PAN_L
	NOTE F_, 4
	INSTR 2
	PAN_R
	NOTE F_, 4
	WAIT
	PAN_C
	NEXT
Pat_5E22:
	LEN 7
	INSTR 25
	NOTE C_, 3
	LENGTH $FC
	WAIT
	LENGTH $4D
	WAIT
	LEN 7
	PAN_R
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	LEN 2
	NOTE G_, 5
	LEN 5
	NOTE A_, 5
	LEN 7
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	PAN_C
	NEXT

; PlaySong2: called by the game.
PlaySong2:
	push de
	push bc
	push hl
	call StopAll
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	call StartMusicCh1
	ld a, $FF
	ldh [rNR51], a
	ldh [hShNR51], a
	pop hl
	pop bc
	pop de
	ret
Song2_Ch3:
	dw Pat_5E77
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_5E8B
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_5EA2
	ORDER_LOOP Song2_Ch1
Pat_5E77:
	PAN_C
	LEN 24
	INSTR 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_5E8B:
	PAN_C
	LEN 6
	WAIT
	LEN 24
	INSTR 20
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 18
	WAIT
	NEXT
Pat_5EA2:
	PAN_C
	LEN 24
	INSTR 22
	NOTE A_, 2
	LEN 12
	NOTE A_, 2
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	LEN 24
	WAIT
	WAIT
	WAIT
	WAIT
	STOP_ALL
	db $73

; Instrument table: instrument n = entry n (code reads InstrTable - 2 + 2*(byte - $7F)).
InstrTable:
	dw Instr00
	dw Instr00
	dw Instr00
	dw Instr03
	dw Instr04
	dw Instr04
	dw Instr06
	dw Instr07
	dw Instr08
	dw Instr09
	dw Instr0A
	dw Instr0B
	dw Instr0C
	dw Instr0C
	dw Instr0E
	dw Instr0E
	dw Instr10
	dw Instr10
	dw Instr10
	dw Instr13
	dw Instr13
	dw Instr15
	dw Instr15
	dw Instr17
	dw Instr17
	dw Instr17
Instr00:
	DUTY_50
	VOLENV 15, $11, $1F, $11
	VIBRATO $00, $01, $01
	GLIDE $FE
	MASK_A
	END
Instr03:
	DUTY_50
	VOLENV 15, $14, $1F, $11
	VIBRATO $00, $19, $01
	GLIDE $FE
	ARP 0
	MASK_A
	END
Instr04:
	DUTY_50
	VOLENV 10, $10, $1F, $11
	VIBRATO $03, $01, $04
	MASK_A
	END
Instr06:
	DUTY_50
	VOLENV 15, $13, $11, $11
	VIBRATO $05, $01, $04
	ARP 0
	MASK_A
	END
Instr07:
	DUTY_50
	VOLENV 15, $11, $1F, $1B
	VIBRATO $06, $01, $04
	ARP 0
	MASK_A
	END
Instr08:
	DUTY_75
	VOLENV 15, $12, $26, $11
	VIBRATO $00, $02, $04
	ARP 2
	MASK_A
	END
Instr09:
	DUTY_50
	VOLENV 15, $11, $53, $1B
	VIBRATO $06, $10, $02
	ARP 0
	MASK_A
	END
Instr0A:
	DUTY_50
	VOLENV 10, $15, $1F, $39
	VIBRATO $01, $00, $01
	ARP 2
	MASK_A
	END
Instr0B:
	DUTY_50
	VOLENV 15, $15, $23, $11
	VIBRATO $06, $02, $04
	ARP 0
	MASK_A
	END
Instr0C:
	DUTY_50
	VOLENV 15, $11, $1F, $19
	VIBRATO $06, $09, $04
	ARP 0
	MASK_A
	END
Instr0E:
	DUTY_75
	VOLENV 15, $12, $2F, $11
	VIBRATO $24, $00, $00
	ARP 0
	MASK_A
	END
Instr10:
	DUTY_12
	VOLENV 7, $26, $1F, $14
	VIBRATO $06, $01, $04
	ARP 0
	MASK_A
	END
Instr13:
	DUTY_50
	VOLENV 12, $15, $1F, $47
	VIBRATO $08, $02, $04
	ARP 0
	MASK_A
	END
Instr15:
	DUTY_50
	VOLENV 15, $00, $1F, $02
	VIBRATO $06, $03, $01
	ARP 0
	MASK_A
	END
Instr17:
	DUTY_50
	VOLENV 12, $11, $1F, $1A
	VIBRATO $06, $01, $04
	ARP 0
	MASK_A
	END

; Arpeggio table: 15 pointers. Only 0-2 point to arpeggio data; 3-14 point into
; SfxTable_m2 (garbage, not used by the songs).
ArpTable:
	dw Arp00
	dw Arp01
	dw Arp01
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
	dw SfxTable
Arp00:
	db $0C
	db $00
	db $00
	db ARP_HOLD
Arp01:
	db $0C
	db $07
	db $00
	db $04
	db ARP_LOOP

; Sound table: ids 1-7 (code reads SfxTable - 2 + 2*id; id 0 would read the word $7304).
SfxTable:
	dw Sfx01
	dw Sfx02
	dw Sfx03
	dw Sfx04
	dw Sfx05
	dw Sfx06
	dw Sfx07
Sfx01:
	MASK_A
	VOLENV 15, $00, $1F, $1C
	LEN 32
	VIBRATO $01, $01, $01
	NOTE B_, 3
	END
Sfx02:
	MASK_A
	VOLENV 15, $14, $1F, $11
	LEN 2
	VIBRATO $06, $14, $04
	NOTE G_, 5
	MASK_A
	LEN 12
	WAIT
	END
Sfx03:
	MASK_A
	VOLENV 15, $00, $1F, $11
	LEN 7
	NOTE C_, 5
	END
Sfx04:
	VOLENV 15, $00, $1F, $15
	MASK_A
	LEN 1
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 13
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 11
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 9
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 7
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END
Sfx05:
	VOLENV 15, $00, $1F, $15
	MASK_A
	LEN 1
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 13
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 11
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 9
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 7
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 5
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	END
Sfx06:
	VOLENV 15, $00, $1F, $19
	MASK_A
	LEN 1
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END
Sfx07:
	NOISE_HIT2
