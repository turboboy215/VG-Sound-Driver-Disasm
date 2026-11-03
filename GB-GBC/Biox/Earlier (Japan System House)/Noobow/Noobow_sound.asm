; Noobow (J) - sound driver A, bank $0F $4000-$6E1C
; Biox / Japan System House. Disassembled for GBAudioLab\Biox.
; Assemble: rgbasm -o noobow.o Noobow_sound.asm ; rgblink -o noobow.gb noobow.o

INCLUDE "hardware.inc"
INCLUDE "bioxA_sound.inc"

; ---- RAM (identical in Noobow and Pocket Bowling) ----
DEF hSndPtrCh1    EQU $FFC0   ; track pointers, $FFFF = channel off
DEF hSndPtrCh2    EQU $FFC2
DEF hSndPtrCh3    EQU $FFC4
DEF hSndPtrCh4    EQU $FFC6
DEF hSndPtrSfx2   EQU $FFC8   ; SFX track on hardware ch2
DEF hSndPtrSfx4   EQU $FFCA   ; SFX track on hardware ch4
DEF hSndTempo     EQU $FFCC   ; TMA value for the music timer
DEF hSndUnusedCD  EQU $FFCD   ; written by $E6, never read
DEF hSndUnusedCE  EQU $FFCE   ; word written by $E6/$E7/$E8, never read
DEF hSndLastNote  EQU $FFD0   ; [6] last note byte per track (index c = 0-5)
DEF hSndLastLen   EQU $FFD6   ; [6] last length in ticks
DEF hSndLenCount  EQU $FFDC   ; [6] ticks left on the current row
DEF hSndInst      EQU $FFE2   ; [6] $E2 value (envelope sequence / wave)
DEF hSndCurMusic  EQU $FFED   ; last music id started
DEF hSndCurSfx    EQU $FFEE   ; last SFX id started
DEF wSndCh1       EQU $DE00   ; 6 track structs of $1E bytes
DEF wSndCh2       EQU $DE1E
DEF wSndCh3       EQU $DE3C
DEF wSndCh4       EQU $DE5A
DEF wSndSfx2      EQU $DE78
DEF wSndSfx4      EQU $DE96
DEF wSndLastByte  EQU $DEC8   ; last track byte parsed (checked for $F3)
DEF wSndSfxOwns   EQU $DEC9   ; $FF while the SFX track owns the channel being updated
DEF wSndSlur      EQU $DECA   ; set by $F5
DEF wSndVibNew    EQU $DECB   ; set by $E4
DEF wSndInstNew   EQU $DECC   ; set by $E2
DEF wSndChanOfs   EQU $DECD   ; word: offset of current struct from wSndCh1
DEF wSndRegOfs    EQU $DECF   ; NRx0 offset of current channel (0/5/10/15)
DEF wSndProfStart EQU $DED0   ; LY at start of the timer update
DEF wSndProfEnd   EQU $DED1   ; LY at end
DEF wSndProfAvg   EQU $DED2   ; running average of lines used
DEF wSndProfValid EQU $DED3   ; 0 until the first measurement
DEF wSndProfMax   EQU $DED4   ; maximum lines used
DEF wSndEnvPtr    EQU $DED5   ; [6 words] envelope-sequence pointers
DEF wSndEnvCount  EQU $DEE1   ; [6] envelope-sequence step counters
DEF wSndTrigger   EQU $DEE7   ; $80 when the envelope stepper rewrote NRx2
DEF wSndNewRow    EQU $DEE8   ; $FF when a new row was parsed this tick

SECTION "Sound Driver A (Noobow)", ROMX[$4000], BANK[$F]

SndEntry_Play:
	jp Snd_Play
SndEntry_TimerUpdate:
	jp Snd_TimerUpdate
SndEntry_FrameUpdate:
	jp Snd_FrameUpdate
SndEntry_Init:
	jp Snd_Init
SndEntry_IsSfxIdle:
	jp Snd_IsSfxIdle
Snd_IsSfxIdle:
	push hl
	ld hl,hSndPtrSfx2
	ld a,[hli]
	and [hl]
	inc hl
	and [hl]
	inc hl
	and [hl]
	cp $FF
	pop hl
	ret
Snd_Play:
	di
	push af
	push hl
	push de
	push bc
	cp $08
	jr nc,Snd_PlaySfx
	ldh [hSndCurMusic],a
	sla a
	ld l,a
	ld h,$00
	ld de,SndMusicTable
	add hl,de
	ld e,[hl]
	inc hl
	ld d,[hl]
	push de
	pop hl
	ld a,[hli]
	ldh [hSndPtrCh1],a
	ld a,[hli]
	ldh [hSndPtrCh1+1],a
	ld a,[hli]
	ldh [hSndPtrCh2],a
	ld a,[hli]
	ldh [hSndPtrCh2+1],a
	ld a,[hli]
	ldh [hSndPtrCh3],a
	ld a,[hli]
	ldh [hSndPtrCh3+1],a
	ld a,[hli]
	ldh [hSndPtrCh4],a
	ld a,[hli]
	ldh [hSndPtrCh4+1],a
	ld hl,hSndLenCount
	xor a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh1+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh2+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh3+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndCh4+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld a,$FF
	ldh [rNR50],a
	ldh [rNR51],a
	ldh [rNR52],a
	xor a
	ld [wSndProfValid],a
	ld [wSndProfMax],a
	pop bc
	pop de
	pop hl
	pop af
	ei
	ret
Snd_PlaySfx:
	ldh [hSndCurSfx],a
	sub $08
	sla a
	ld l,a
	ld h,$00
	ld de,SndSfxTable
	add hl,de
	ld e,[hl]
	inc hl
	ld d,[hl]
	push de
	pop hl
	ld a,[hli]
	ldh [hSndPtrSfx2],a
	ld a,[hli]
	ldh [hSndPtrSfx2+1],a
	ld a,[hli]
	ldh [hSndPtrSfx4],a
	ld a,[hli]
	ldh [hSndPtrSfx4+1],a
	xor a
	ldh [hSndLenCount+4],a
	ldh [hSndLenCount+5],a
	ld hl,wSndSfx2+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,wSndSfx4+$11
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld a,$FF
	ldh [rNR50],a
	ldh [rNR51],a
	ldh [rNR52],a
	pop bc
	pop de
	pop hl
	pop af
	ei
	ret
Snd_Unused40CC:
	push af
	push hl
	push de
	push bc
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_Init:
	di
	push af
	push hl
	push de
	push bc
	ld hl,hSndPtrCh1
	ld a,$FF
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld hl,hSndLenCount
	xor a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld a,$FF
	ldh [rNR31],a
	ld a,$00
	ldh [rNR32],a
	ld a,$40
	ldh [rNR34],a
	ld a,$40
	ldh [rTIMA],a
	ldh [rTMA],a
	ld a,$04
	ldh [rTAC],a
	ldh a,[rIE]
	or $04
	ldh [rIE],a
	pop bc
	pop de
	pop hl
	pop af
	ei
	ret
Snd_TimerUpdate:
	push af
	push hl
	push de
	push bc
	ldh a,[rLY]
	cp $70
	jr nc,Snd_TimerDefer
	ld [wSndProfStart],a
	ldh a,[hSndTempo]
	ldh [rTIMA],a
	ldh [rTMA],a
	call Snd_UpdateCh1
	call Snd_UpdateCh2
	call Snd_UpdateCh3
	call Snd_UpdateCh4
	ld a,[wSndProfStart]
	ld b,a
	ldh a,[rLY]
	ld [wSndProfEnd],a
	sub b
	ld b,a
	ld a,[wSndProfValid]
	or a
	jr z,Snd_415D
	ld a,[wSndProfAvg]
	add a,b
	srl a
	ld c,b
	ld b,a
	ld a,[wSndProfMax]
	cp c
	jr nc,Snd_4159
	ld a,c
	ld [wSndProfMax],a
Snd_4159:
	ld a,b
	ld [wSndProfAvg],a
Snd_415D:
	ld a,$FF
	ld [wSndProfValid],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_TimerDefer:
	ld a,$E6
	ldh [rTIMA],a
	ldh [rTMA],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_FrameUpdate:
	push af
	push hl
	push de
	push bc
	call Snd_UpdateSfx2
	call Snd_UpdateSfx4
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_UpdateSfx2:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx2]
	ld l,a
	ldh a,[hSndPtrSfx2+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_41C0
	ld a,$78
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$05
	ld [wSndRegOfs],a
	ld c,$04
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrSfx2],a
	ld a,h
	ldh [hSndPtrSfx2+1],a
	and l
	cp $FF
	jr z,Snd_41C0
	ldh a,[hSndLastNote+4]
	and $0F
	cp $0D
	jr nc,Snd_41C0
	call Snd_EnvStep
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_41C0:
	ret
Snd_UpdateSfx4:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx4]
	ld l,a
	ldh a,[hSndPtrSfx4+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_41F7
	ld a,$96
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$0F
	ld [wSndRegOfs],a
	ld c,$05
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrSfx4],a
	ld a,h
	ldh [hSndPtrSfx4+1],a
	and l
	cp $FF
	jr z,Snd_41F7
	ldh a,[hSndLastNote+5]
	and $0F
	cp $0D
	jr nc,Snd_41F7
Snd_41F7:
	ret
Snd_UpdateCh1:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrCh1]
	ld l,a
	ldh a,[hSndPtrCh1+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_423E
	ld a,$00
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$00
	ld [wSndRegOfs],a
	ld c,$00
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh1],a
	ld a,h
	ldh [hSndPtrCh1+1],a
	and l
	cp $FF
	jr z,Snd_423E
	ldh a,[hSndLastNote]
	and $0F
	cp $0D
	jr nc,Snd_423E
	ld a,[wSndNewRow]
	or a
	jr nz,Snd_423D
	call Snd_EnvStep
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_423D:
	ret
Snd_423E:
	xor a
	ldh [rNR12],a
	ret
Snd_UpdateCh2:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx2]
	ld l,a
	ldh a,[hSndPtrSfx2+1]
	and l
	cp $FF
	jr z,Snd_4255
	ld a,$FF
	ld [wSndSfxOwns],a
Snd_4255:
	ldh a,[hSndPtrCh2]
	ld l,a
	ldh a,[hSndPtrCh2+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_4297
	ld a,$1E
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$05
	ld [wSndRegOfs],a
	ld c,$01
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh2],a
	ld a,h
	ldh [hSndPtrCh2+1],a
	and l
	cp $FF
	jr z,Snd_4297
	ldh a,[hSndLastNote+1]
	and $0F
	cp $0D
	jr nc,Snd_4297
	ld a,[wSndNewRow]
	or a
	jr nz,Snd_4296
	call Snd_EnvStep
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_4296:
	ret
Snd_4297:
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_42A0
	xor a
	ldh [rNR22],a
Snd_42A0:
	ret
Snd_UpdateCh3:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrCh3]
	ld l,a
	ldh a,[hSndPtrCh3+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_42EA
	ld a,$3C
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$0A
	ld [wSndRegOfs],a
	ld c,$02
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh3],a
	ld a,h
	ldh [hSndPtrCh3+1],a
	and l
	cp $FF
	jr z,Snd_42EA
	ldh a,[hSndLastNote+2]
	and $0F
	cp $0D
	jr nc,Snd_42EA
	ldh a,[hSndLenCount+2]
	cp $00
	jr z,Snd_42EA
	ld a,[wSndNewRow]
	or a
	jr nz,Snd_42E9
	call Snd_VibratoStep
	call Snd_FreqOut
Snd_42E9:
	ret
Snd_42EA:
	xor a
	ldh [rNR32],a
	ret
Snd_UpdateCh4:
	xor a
	ld [wSndSfxOwns],a
	ldh a,[hSndPtrSfx4]
	ld l,a
	ldh a,[hSndPtrSfx4+1]
	and l
	cp $FF
	jr z,Snd_4301
	ld a,$FF
	ld [wSndSfxOwns],a
Snd_4301:
	ldh a,[hSndPtrCh4]
	ld l,a
	ldh a,[hSndPtrCh4+1]
	ld h,a
	and l
	cp $FF
	jr z,Snd_4334
	ld a,$5A
	ld [wSndChanOfs],a
	ld a,$00
	ld [wSndChanOfs+1],a
	ld a,$0F
	ld [wSndRegOfs],a
	ld c,$03
	call Snd_ParseTrack
	ld a,l
	ldh [hSndPtrCh4],a
	ld a,h
	ldh [hSndPtrCh4+1],a
	and l
	cp $FF
	jr z,Snd_4334
	ldh a,[hSndLastNote+3]
	and $0F
	cp $0D
	jr nc,Snd_4334
	ret
Snd_4334:
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_433D
	xor a
	ldh [rNR42],a
Snd_433D:
	ret
Snd_ParseTrack:
	xor a
	ld [wSndSlur],a
	ld [wSndVibNew],a
	ld [wSndInstNew],a
	ld [wSndTrigger],a
	ld [wSndNewRow],a
	ld a,c
	add a,$DC
	ld e,a
	ld a,$00
	adc a,$FF
	ld d,a
	ld a,[de]
	or a
	jp nz,Snd_ParseDone
	ld a,$FF
	ld [wSndNewRow],a
Snd_ParseLoop:
	ld a,l
	and h
	cp $FF
	jp z,Snd_TrackEnd
	ld a,[hl]
	cp $A0
	jr nc,Snd_439D
	ld [wSndLastByte],a
Snd_4370:
	call Snd_NoteEnvelope
	ld a,[hl]
	inc hl
	push hl
	ld b,$00
	ld hl,hSndLastNote
	add hl,bc
	ld [hl],a
	pop hl
	call Snd_NoteFreq
	call Snd_NoteVibrato
	ld a,[hl]
	cp $A0
	jr c,Snd_438D
	cp $B0
	jr c,Snd_43BB
Snd_438D:
	push hl
	ld b,$00
	ld hl,hSndLastLen
	add hl,bc
	ld a,[hl]
	ld hl,hSndLenCount
	add hl,bc
	ld [hl],a
	pop hl
	jr Snd_ParseDone
Snd_439D:
	ld a,[hl]
	cp $B0
	jr nc,Snd_43DA
	ld a,[wSndLastByte]
	cp $F3
	jr z,Snd_43BB
	call Snd_NoteEnvelope
	push hl
	ld b,$00
	ld hl,hSndLastNote
	add hl,bc
	ld a,[hl]
	pop hl
	call Snd_NoteFreq
	call Snd_NoteVibrato
Snd_43BB:
	ld a,[hl]
	ld [wSndLastByte],a
	inc hl
	push hl
	ld hl,SndLengthTable
	and $0F
	ld e,a
	ld d,$00
	add hl,de
	ld d,[hl]
	ld b,$00
	ld hl,hSndLenCount
	add hl,bc
	ld [hl],d
	ld hl,hSndLastLen
	add hl,bc
	ld [hl],d
	pop hl
	jr Snd_ParseDone
Snd_43DA:
	ld a,[hl]
	cp $E0
	jr c,Snd_TrackEnd
	inc hl
	ld [wSndLastByte],a
	push hl
	pop de
	sub $E0
	call Snd_RunCommand
	push de
	pop hl
	jp Snd_ParseLoop
Snd_ParseDone:
	push hl
	ld b,$00
	ld hl,hSndLenCount
	add hl,bc
	dec [hl]
	pop hl
	ret
Snd_TrackEnd:
	ld hl,$FFFF
	ret
Snd_RunCommand:
	ld l,a
	sla l
	ld h,$00
	push de
	ld de,SndCommandTable
	add hl,de
	ld e,[hl]
	inc hl
	ld d,[hl]
	push de
	pop hl
	pop de
	jp hl
SndCommandTable:
	dw SndCmd_End, SndCmd_Sweep, SndCmd_Inst, SndCmd_Duty
	dw SndCmd_Vibrato, SndCmd_Env, SndCmd_Tempo, SndCmd_UnusedE7
	dw SndCmd_UnusedE8, SndCmd_End, SndCmd_End, SndCmd_Pan
	dw SndCmd_End, SndCmd_End, SndCmd_Call, SndCmd_Ret
	dw SndCmd_Loop, SndCmd_Jump, SndCmd_MasterVol, SndCmd_Tie
	dw SndCmd_RawNote, SndCmd_Slur, SndCmd_End, SndCmd_End
	dw SndCmd_End, SndCmd_End, SndCmd_End, SndCmd_End
	dw SndCmd_End, SndCmd_End, SndCmd_End, SndCmd_EndFF
SndCmd_End:
	ld de,$FFFF
	ret
SndCmd_EndFF:
	ld de,$FFFF
	ret
Snd_AddChanOfs:
	push af
	ld a,[wSndChanOfs]
	add a,l
	ld l,a
	ld a,[wSndChanOfs+1]
	adc a,h
	ld h,a
	pop af
	ret
Snd_GetReg:
	push de
	ld e,a
	ld a,[wSndRegOfs]
	add a,e
	ld c,a
	pop de
	ret
SndCmd_Sweep:
	ld a,c
	cp $00
	jr nz,Snd_4474
	ld a,[de]
	ldh [rNR10],a
Snd_4474:
	inc de
	ret
SndCmd_Inst:
	push bc
	ld a,$E2
	add a,c
	ld c,a
	ld a,[de]
	ldh [c],a
	ld a,$FF
	ld [wSndInstNew],a
	inc de
	pop bc
	ret
SndCmd_Duty:
	ld a,c
	cp $00
	jr nz,Snd_448D
	ld a,[de]
	ldh [rNR11],a
Snd_448D:
	inc de
	ret
SndCmd_Vibrato:
	ld hl,wSndCh1+$07
	call Snd_AddChanOfs
	ld a,[de]
	ld [hl],a
	inc de
	ld a,$FF
	ld [wSndVibNew],a
	ret
SndCmd_Env:
	ld hl,wSndCh1+$05
	call Snd_AddChanOfs
	ld a,[de]
	ld [hl],a
	inc de
	ret
SndCmd_Tempo:
	ld a,[de]
	or a
	jr z,Snd_44B3
	ldh [hSndTempo],a
	ldh [rTIMA],a
	ldh [rTMA],a
	xor a
Snd_44B3:
	ldh [hSndUnusedCD],a
	ldh [hSndUnusedCE],a
	ldh [hSndUnusedCE+1],a
	inc de
	ret
SndCmd_UnusedE7:
	push de
	pop hl
	xor a
	sub [hl]
	ldh [hSndUnusedCE],a
	inc hl
	ld a,$00
	sbc a,[hl]
	ldh [hSndUnusedCE+1],a
	inc de
	inc de
	ret
SndCmd_UnusedE8:
	ld a,[de]
	ldh [hSndUnusedCE],a
	inc de
	ld a,[de]
	ldh [hSndUnusedCE+1],a
	inc de
	ret
SndCmd_Pan:
	ld a,[de]
	inc de
	push de
	push bc
	ld l,a
	ld h,$00
	ld de,SndPanTable
	add hl,de
	ld d,[hl]
	ld e,$77
	ld a,c
	cp $04
	jr nz,Snd_44E8
	ld a,$01
Snd_44E8:
	cp $05
	jr nz,Snd_44EE
	ld a,$03
Snd_44EE:
	rlc e
	rlc d
	sub $01
	jr nc,Snd_44EE
	ldh a,[rNR51]
	and e
	or d
	ldh [rNR51],a
	pop bc
	pop de
	ret
SndPanTable:
	db $00, $80, $08, $88
SndCmd_Call:
	ld hl,wSndCh1+$15
	call Snd_AddChanOfs
	ld a,[hl]
	cp $04
	jp nc,SndCmd_End
	inc [hl]
	inc hl
	sla a
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld a,e
	add a,$02
	ld [hli],a
	ld a,$00
	adc a,d
	ld [hl],a
	ld a,[de]
	ld l,a
	inc de
	ld a,[de]
	ld h,a
	push hl
	pop de
	ret
SndCmd_Ret:
	ld hl,wSndCh1+$15
	call Snd_AddChanOfs
	ld a,[hl]
	or a
	jp z,SndCmd_End
	dec [hl]
	inc hl
	dec a
	sla a
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld e,[hl]
	inc hl
	ld d,[hl]
	ret
SndCmd_Loop:
	ld hl,wSndCh1+$11
	call Snd_AddChanOfs
	ld a,[de]
	inc de
	ld b,a
	ld a,[de]
	inc de
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld a,b
	cp [hl]
	jr z,Snd_4560
	ld a,[de]
	ld l,a
	inc de
	ld a,[de]
	ld h,a
	push hl
	pop de
	ret
Snd_4560:
	ld [hl],$00
	inc de
	inc de
	ret
SndCmd_Jump:
	push de
	pop hl
	ld e,[hl]
	inc hl
	ld d,[hl]
	ret
SndCmd_MasterVol:
	ld a,[de]
	inc de
	ldh [rNR50],a
	ret
SndCmd_Tie:
	ret
SndCmd_RawNote:
	pop af
	ld a,[de]
	push de
	pop hl
	jp Snd_4370
SndCmd_Slur:
	ld [wSndSlur],a
	ret
Snd_NoteEnvelope:
	push af
	push hl
	push de
	push bc
	ld a,[wSndSfxOwns]
	ld b,a
	ld a,[wSndSlur]
	or b
	jr nz,Snd_45D1
	ld a,c
	cp $02
	jr z,Snd_NoteWave
	ld b,$00
	ld hl,hSndInst
	add hl,bc
	ld a,[hl]
	or a
	jr z,Snd_45C4
	add a,a
	ld hl,SndEnvTable
	add a,l
	ld l,a
	ld a,$00
	adc a,h
	ld h,a
	ld e,[hl]
	inc hl
	ld d,[hl]
	inc de
	inc de
	ld hl,wSndEnvPtr
	add hl,bc
	add hl,bc
	ld [hl],e
	inc hl
	ld [hl],d
	dec de
	dec de
	ld hl,wSndEnvCount
	add hl,bc
	ld a,[de]
	ld [hl],a
	inc de
	ld a,[de]
	ld hl,wSndCh1+$05
	call Snd_AddChanOfs
	ld [hl],a
	jp Snd_45CA
Snd_45C4:
	ld hl,wSndCh1+$05
	call Snd_AddChanOfs
Snd_45CA:
	ld a,$12
	call Snd_GetReg
	ld a,[hl]
	ldh [c],a
Snd_45D1:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_NoteWave:
	ld a,$7F
	ldh [rNR30],a
	ld a,[wSndInstNew]
	or a
	jr z,Snd_45FE
	ldh a,[hSndInst+2]
	sla a
	sla a
	sla a
	sla a
	ld l,a
	ld h,$00
	ld de,SndWaveTable
	add hl,de
	ld c,$30
	ld a,$0F
Snd_45F5:
	push af
	ld a,[hli]
	ldh [c],a
	inc c
	pop af
	sub $01
	jr nc,Snd_45F5
Snd_45FE:
	ld a,[wSndCh3+$05]
	ldh [rNR32],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_NoteVibrato:
	push af
	push hl
	push de
	push bc
	ld a,c
	cp $03
	jr z,Snd_465D
	cp $05
	jr z,Snd_465D
	ld a,[wSndSlur]
	or a
	jr nz,Snd_464A
	ld a,[wSndVibNew]
	or a
	jr z,Snd_464F
	ld hl,wSndCh1+$07
	call Snd_AddChanOfs
	ld a,[hl]
	sla a
	sla a
	ld e,a
	ld d,$00
	push hl
	ld hl,SndVibratoTable
	add hl,de
	pop de
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	inc de
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	xor a
	inc de
	ld [de],a
	inc de
	ld [de],a
Snd_464A:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_464F:
	ld hl,wSndCh1+$0F
	call Snd_AddChanOfs
	xor a
	ld [hli],a
	ld [hli],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_465D:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_EnvStep:
	ld b,$00
	ld hl,hSndInst
	add hl,bc
	ld a,[hl]
	or a
	jr z,Snd_46A4
	ld hl,wSndEnvCount
	add hl,bc
	ld a,[hl]
	or a
	jr nz,Snd_469D
	ld hl,wSndEnvPtr
	add hl,bc
	add hl,bc
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld a,[de]
	or a
	jr z,Snd_46A4
	ld hl,wSndEnvCount
	add hl,bc
	ld [hl],a
	inc de
	push bc
	ld a,$12
	call Snd_GetReg
	ld a,[de]
	ldh [c],a
	pop bc
	inc de
	ld hl,wSndEnvPtr
	add hl,bc
	add hl,bc
	ld [hl],e
	inc hl
	ld [hl],d
	ld a,$80
	ld [wSndTrigger],a
Snd_469D:
	ld b,$00
	ld hl,wSndEnvCount
	add hl,bc
	dec [hl]
Snd_46A4:
	ret
Snd_VibratoStep:
	ld a,c
	cp $03
	jp z,Snd_472A
	cp $05
	jp z,Snd_472A
	ld hl,wSndCh1+$08
	call Snd_AddChanOfs
	ld a,[hl]
	or a
	jr z,Snd_46C0
	dec [hl]
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_46C0:
	ld de,$0003
	add hl,de
	ld a,[hli]
	or a
	jr z,Snd_46DB
	ld a,[hl]
	or a
	jr nz,Snd_46DB
	dec hl
	ld a,[hli]
	ld [hli],a
	ld a,[hli]
	xor $FF
	ld e,a
	ld a,[hl]
	xor $FF
	ld d,a
	inc de
	ld [hl],d
	dec hl
	ld [hl],e
Snd_46DB:
	ld hl,wSndCh1+$0D
	call Snd_AddChanOfs
	ld e,[hl]
	inc hl
	ld d,[hl]
	inc hl
	ld a,[hl]
	add a,e
	ld [hli],a
	ld e,a
	ld a,[hl]
	adc a,d
	ld [hl],a
	ld d,a
	sra d
	rr e
	sra d
	rr e
	sra d
	rr e
	ld hl,wSndCh1+$09
	call Snd_AddChanOfs
	ld a,e
	add a,[hl]
	ld e,a
	inc hl
	ld a,d
	adc a,[hl]
	ld d,a
	ld a,c
	ld hl,wSndCh1+$03
	cp $00
	jr z,Snd_471F
	ld hl,wSndCh2+$03
	cp $01
	jr z,Snd_471F
	ld hl,wSndCh3+$03
	cp $02
	jr z,Snd_471F
	ld hl,wSndSfx2+$03
Snd_471F:
	ld [hl],e
	inc hl
	ld [hl],d
	ld hl,wSndCh1+$0C
	call Snd_AddChanOfs
	dec [hl]
	ret
Snd_472A:
	ret
Snd_NoteFreq:
	push af
	push hl
	push de
	push bc
	ld b,a
	ld a,c
	cp $05
	jr z,Snd_474D
	cp $03
	jr nz,Snd_475B
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_4748
	ld a,b
	swap a
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
Snd_4748:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_474D:
	ld a,b
	swap a
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_475B:
	ld a,b
	sub $10
	ld b,a
	and $0F
	cp $0D
	jr nc,Snd_47C4
	ld a,b
	and $7F
	sla a
	ld l,a
	ld h,$00
	ld de,SndFreqTable
	add hl,de
	ld e,[hl]
	inc hl
	ld d,[hl]
	ld hl,wSndCh1+$09
	call Snd_AddChanOfs
	ld [hl],e
	inc hl
	ld [hl],d
	ld a,d
	and $07
	or $80
	ld d,a
	ld a,[wSndSlur]
	or a
	jr z,Snd_478D
	ld a,d
	and $7F
	ld d,a
Snd_478D:
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_47A8
	ld a,c
	cp $02
	jr nz,Snd_479C
	ld a,$FF
	ldh [rNR30],a
Snd_479C:
	push bc
	ld a,$13
	call Snd_GetReg
	ld a,e
	ldh [c],a
	inc c
	ld a,d
	ldh [c],a
	pop bc
Snd_47A8:
	ld a,c
	ld hl,wSndCh1+$03
	cp $00
	jr z,Snd_47C1
	ld hl,wSndCh2+$03
	cp $01
	jr z,Snd_47C1
	ld hl,wSndCh3+$03
	cp $02
	jr z,Snd_47C1
	ld hl,wSndSfx2+$03
Snd_47C1:
	ld [hl],e
	inc hl
	ld [hl],d
Snd_47C4:
	pop bc
	pop de
	pop hl
	pop af
	ret
Snd_FreqOut:
	push af
	push hl
	push de
	push bc
	ld a,[wSndSfxOwns]
	or a
	jr nz,Snd_480C
	ld a,c
	ld de,wSndCh1+$03
	cp $00
	jr z,Snd_47EC
	ld de,wSndCh2+$03
	cp $01
	jr z,Snd_47EC
	ld de,wSndCh3+$03
	cp $02
	jr z,Snd_47EC
	ld de,wSndSfx2+$03
Snd_47EC:
	ld a,[de]
	ld l,a
	inc de
	ld a,[de]
	ld h,a
	cp $08
	jr c,Snd_47FF
	ld hl,$07FF
	cp $80
	jr c,Snd_47FF
	ld hl,$0000
Snd_47FF:
	ld a,$13
	call Snd_GetReg
	ld a,l
	ldh [c],a
	inc c
	ld a,[wSndTrigger]
	or h
	ldh [c],a
Snd_480C:
	pop bc
	pop de
	pop hl
	pop af
	ret
SndFreqTable:
	dw $002C, $009D, $0107, $016B, $01CA, $0223, $0277, $02C7, $0312, $0359, $039B, $03DA, $0416, $0000, $0000, $0000
	dw $0416, $044E, $0483, $04B5, $04E5, $0511, $053B, $0563, $0589, $05AC, $05CD, $05ED, $060B, $0000, $0000, $0000
	dw $060B, $0627, $0641, $065A, $0672, $0688, $069D, $06B1, $06C4, $06D6, $06E6, $06F6, $0705, $0000, $0000, $0000
	dw $0705, $0713, $0720, $072D, $0739, $0744, $074E, $0758, $0762, $076B, $0773, $077B, $0782, $0000, $0000, $0000
	dw $0782, $0789, $0790, $0796, $079C, $07A2, $07A7, $07AC, $07B1, $07B5, $07B9, $07BD, $07C1, $0000, $0000, $0000
	dw $07C1, $07C4, $07C8, $07CB, $07CE, $07D1, $07D3, $07D6, $07D8, $07DA, $07DC, $07DE, $07E0, $0000, $0000, $0000
	dw $07E0, $07E2, $07E4, $07E5, $07E7, $07E8, $07E9, $07EB, $07EC, $07ED, $07EE, $07EF, $07F0, $0000, $0000, $0000
	dw $07F0, $07F1, $07F2, $07F3, $07F3, $07F4, $07F4, $07F5, $07F6, $07F6, $07F7, $07F7, $07F8, $0000, $0000, $0000
SndLengthTable:
	db $02, $03, $04, $06, $09, $08, $0C, $12, $10, $18, $24, $20, $30, $48, $40, $60
SndEnvTable:
	dw SndEnv0, SndEnv1, SndEnv2
SndEnv0:
	db $80, $00
	db $86, $00
	db $00	; end
	db $00	; end
SndEnv1:
	db $05, $93
	db $05, $83
	db $05, $73
	db $05, $63
	db $05, $53
	db $05, $53
	db $05, $53
	db $05, $43
	db $05, $43
	db $05, $43
	db $05, $33
	db $05, $33
	db $05, $33
	db $05, $23
	db $05, $23
	db $05, $23
	db $05, $23
	db $05, $23
	db $05, $23
	db $05, $26
	db $00	; end
SndEnv2:
	db $03, $F2
	db $03, $E2
	db $03, $D2
	db $03, $C2
	db $03, $B2
	db $03, $B2
	db $03, $B2
	db $03, $A2
	db $03, $A2
	db $03, $A2
	db $03, $92
	db $03, $92
	db $03, $92
	db $03, $82
	db $03, $82
	db $03, $82
	db $03, $82
	db $03, $82
	db $03, $82
	db $03, $82
	db $00	; end
SndWaveTable:
	db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88	; wave $00
	db $88, $88, $77, $77, $66, $66, $55, $55, $44, $44, $33, $33, $22, $21, $11, $00	; wave $01
	db $88, $77, $66, $55, $44, $33, $22, $10, $00, $00, $00, $00, $00, $00, $00, $00	; wave $02
	db $87, $65, $42, $10, $01, $24, $56, $78, $87, $65, $42, $10, $01, $24, $56, $78	; wave $03
	db $87, $65, $42, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; wave $04
	db $86, $46, $86, $46, $86, $46, $86, $46, $86, $46, $86, $46, $86, $46, $86, $46	; wave $05
	db $88, $77, $66, $55, $44, $33, $22, $11, $00, $11, $22, $33, $44, $55, $66, $77	; wave $06
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $07
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $08
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $09
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $0A
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $0B
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $0C
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $0D
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $0E
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; wave $0F
SndVibratoTable:
	db $00, $00
	dw $0000	; vibrato $00: delay, half-period, step
	db $00, $04
	dw $0004	; vibrato $01: delay, half-period, step
	db $00, $07
	dw $0003	; vibrato $02: delay, half-period, step
	db $00, $04
	dw $FFFC	; vibrato $03: delay, half-period, step
	db $00, $08
	dw $FFFC	; vibrato $04: delay, half-period, step
	db $00, $01
	dw $FFC0	; vibrato $05: delay, half-period, step
	db $00, $00
	dw $FFC0	; vibrato $06: delay, half-period, step
	db $00, $00
	dw $FF00	; vibrato $07: delay, half-period, step
	db $00, $10
	dw $0020	; vibrato $08: delay, half-period, step
	db $00, $01
	dw $0100	; vibrato $09: delay, half-period, step
	db $00, $01
	dw $FF00	; vibrato $0A: delay, half-period, step
	db $00, $00
	dw $0001	; vibrato $0B: delay, half-period, step
	db $00, $00
	dw $0040	; vibrato $0C: delay, half-period, step
	db $00, $00
	dw $FFF8	; vibrato $0D: delay, half-period, step
	db $00, $00
	dw $FF80	; vibrato $0E: delay, half-period, step
	db $00, $00
	dw $0080	; vibrato $0F: delay, half-period, step
	db $00, $00
	dw $0000	; vibrato $10: delay, half-period, step
	db $00, $00
	dw $0000	; vibrato $11: delay, half-period, step
	db $00, $04
	dw $0002	; vibrato $12: delay, half-period, step
	db $00, $04
	dw $0008	; vibrato $13: delay, half-period, step
	db $00, $00
	dw $0000	; vibrato $14: delay, half-period, step
	db $00, $00
	dw $0008	; vibrato $15: delay, half-period, step
SndMusicTable:
	dw Mus00, Mus01, Mus02, Mus03, Mus04, Mus05, Mus06, Mus07
Mus00:
	dw Mus00_Ch1, Mus00_Ch2, Mus00_Ch3, Mus00_Ch4
Mus01:
	dw Mus01_Ch1, Mus01_Ch2, Mus01_Ch3, Mus01_Ch4
Mus02:
	dw Mus02_Ch1, Mus02_Ch2, Mus02_Ch3, Mus02_Ch4
Mus04:
	dw Mus04_Ch1, Mus04_Ch2, Mus04_Ch3, Mus04_Ch4
Mus03:
	dw Mus03_Ch1, Mus03_Ch2, Mus03_Ch3, Mus03_Ch4
Mus05:
	dw Mus05_Ch1, Mus05_Ch2, Mus05_Ch3, Mus05_Ch4
Mus06:
	dw Mus06_Ch1, Mus06_Ch2, Mus06_Ch3, Mus06_Ch4
Mus07:
	dw Mus07_Ch1, Mus07_Ch2, Mus07_Ch3, Mus07_Ch4
Mus00_Ch2:
	snd_mastervol $FF
	snd_tempo $BA
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $04
Trk_4B33:
	snd_note C_3, 6
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note C_3
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note C_3
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note C_3
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note F_3
	snd_note F_3
	snd_note A_3
	snd_note A_3
	snd_note C_4
	snd_note C_4
	snd_note D_4
	snd_note C_4
	snd_note F_3
	snd_note F_3
	snd_note A_3
	snd_note A_3
	snd_note C_4
	snd_note C_4
	snd_note D_4
	snd_note C_4
	snd_note C_3
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note C_3
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note G_3
	snd_note G_3
	snd_note B_3
	snd_note B_3
	snd_note D_4
	snd_note D_4
	snd_note E_4
	snd_note D_4
	snd_note F_3
	snd_note F_3
	snd_note A_3
	snd_note A_3
	snd_note C_4
	snd_note C_4
	snd_note D_4
	snd_note C_4
	snd_note C_3
	snd_note C_3
	snd_note E_3
	snd_note E_3
	snd_note G_3
	snd_note G_3
	snd_note A_3
	snd_note G_3
	snd_note C_3, 9
	snd_note B_2, 6
	snd_note C_3, 9
	snd_note B_2, 6
	snd_note C_3, 9
	snd_jump Trk_4B33
	snd_end	; unreachable
Mus00_Ch1:
	snd_inst $00
	snd_env $94
	snd_pan $03
	snd_vibrato $00
	snd_sweep $08
	snd_duty $00
Trk_4BA6:
	snd_note REST, 6
	snd_note E_5
	snd_note Ds_5
	snd_note D_5
	snd_note C_5, 10
	snd_note A_4, 6
	snd_note G_4
	snd_note A_4, 9
	snd_note C_5, 12
	snd_tie
	snd_len 6
	snd_note REST, 6
	snd_note E_5
	snd_note Ds_5
	snd_note D_5
	snd_note C_5, 10
	snd_note A_4, 6
	snd_note G_4
	snd_note A_4, 9
	snd_note C_5
	snd_note G_4, 6
	snd_note A_4
	snd_note C_5
	snd_note D_5, 9
	snd_note E_5, 6
	snd_note C_5, 12
	snd_tie
	snd_len 6
	snd_len 12
	snd_tie
	snd_len 6
	snd_note A_4, 9
	snd_len 6
	snd_len 6
	snd_note G_4
	snd_note E_4
	snd_note G_4, 12
	snd_tie
	snd_len 6
	snd_len 15
	snd_note D_5, 9
	snd_note E_5, 6
	snd_note D_5, 9
	snd_len 6
	snd_note E_5, 9
	snd_note C_5
	snd_note D_5, 6
	snd_note C_5, 9
	snd_len 6
	snd_note D_5, 9
	snd_note G_4
	snd_note A_4, 6
	snd_note G_4, 9
	snd_note A_4, 6
	snd_note G_4
	snd_note A_4
	snd_note C_5, 15
	snd_jump Trk_4BA6
	snd_end	; unreachable
Mus00_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $01
	snd_vibrato $01
	snd_note REST, 15
	snd_note REST
	snd_note REST
	snd_note REST
	snd_note REST
	snd_note REST, 12
	snd_tie
	snd_len 6
	snd_note C_7, 6
	snd_note B_6
	snd_note As_6
	snd_note B_5
	snd_note As_5
	snd_note A_5
	snd_note As_5
	snd_note A_5
	snd_note Gs_5
	snd_note G_5
	snd_note Gs_5
	snd_note G_5
	snd_note Fs_5
	snd_note F_5
	snd_note Fs_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_note E_5
	snd_inst $01
	snd_vibrato $00
	snd_note B_4, 9
	snd_note C_5, 6
	snd_note B_4, 9
	snd_len 6
	snd_note C_5, 9
	snd_note A_4
	snd_note B_4, 6
	snd_note A_4, 9
	snd_len 6
	snd_note B_4, 9
	snd_note E_4
	snd_note F_4, 6
	snd_note E_4, 9
	snd_note F_4, 6
	snd_note E_4
	snd_note F_4
	snd_note A_4, 15
	snd_jump Mus00_Ch3
	snd_end	; unreachable
Mus00_Ch4:
	snd_env $81
	snd_pan $03
	snd_inst $00
	snd_note $0B, 6
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $0B
	snd_note $12
	snd_note $16
	snd_note $0B, 9
	snd_note $12, 6
	snd_len 9
	snd_len 6
	snd_len 9
	snd_jump Mus00_Ch4
	snd_end	; unreachable
Mus01_Ch2:
	snd_mastervol $FF
	snd_tempo $B2
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $04
	snd_note REST, 15
	snd_note REST
Trk_4CC0:
	snd_note C_3, 9
	snd_note E_3
	snd_note G_3
	snd_note A_3, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note C_4, 9
	snd_note A_3
	snd_note G_3
	snd_note E_3
	snd_note C_3
	snd_note E_3
	snd_note G_3
	snd_note A_3, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note As_2, 4
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note F_2, 9
	snd_note A_2
	snd_note F_3
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note F_2, 4
	snd_len 9
	snd_note A_2
	snd_note F_3
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note F_2, 4
	snd_note C_3, 9
	snd_note E_3
	snd_note G_3
	snd_note A_3, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note B_2, 6
	snd_tie
	snd_len 1
	snd_note B_3, 4
	snd_note As_2, 6
	snd_tie
	snd_len 1
	snd_note As_3, 4
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note A_3, 4
	snd_note F_2, 9
	snd_note A_2
	snd_note C_3
	snd_note D_3, 6
	snd_tie
	snd_len 1
	snd_note C_3, 4
	snd_note F_3, 9
	snd_note D_3
	snd_note C_3
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note C_3, 4
	snd_note G_2, 9
	snd_note B_2
	snd_note D_3
	snd_note E_3, 6
	snd_tie
	snd_len 1
	snd_note D_3, 4
	snd_note C_3, 9
	snd_note C_4, 6
	snd_tie
	snd_len 1
	snd_note C_3, 4
	snd_len 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note G_3, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note C_3, 9
	snd_note E_3
	snd_note G_3
	snd_note A_3, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note C_4, 9
	snd_note A_3
	snd_note G_3
	snd_note E_3
	snd_note C_3
	snd_note E_3
	snd_note G_3
	snd_note A_3, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note As_2
	snd_note F_3, 3
	snd_note As_3, 4
	snd_note F_2, 9
	snd_note A_2
	snd_note F_3
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note F_2, 4
	snd_len 9
	snd_note A_2
	snd_note F_3
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note F_2, 4
	snd_note C_3, 9
	snd_note E_3
	snd_note G_3
	snd_note A_3, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note B_2, 6
	snd_tie
	snd_len 1
	snd_note B_3, 4
	snd_note As_2, 6
	snd_tie
	snd_len 1
	snd_note As_3, 4
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note A_3, 4
	snd_note F_2, 9
	snd_note A_2
	snd_note C_3
	snd_note D_3, 6
	snd_tie
	snd_len 1
	snd_note C_3, 4
	snd_note F_3, 9
	snd_note D_3
	snd_note C_3
	snd_note A_2, 6
	snd_tie
	snd_len 1
	snd_note C_3, 4
	snd_note G_2, 9
	snd_note B_2
	snd_note D_3
	snd_note E_3, 6
	snd_tie
	snd_len 1
	snd_note D_3, 4
	snd_note C_3, 9
	snd_note C_4, 6
	snd_tie
	snd_len 1
	snd_note C_3, 4
	snd_len 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note G_3, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 1
	snd_note REST, 3
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note C_3, 6
	snd_tie
	snd_len 1
	snd_note C_4, 4
	snd_note E_3, 6
	snd_tie
	snd_len 1
	snd_note E_4, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note F_2, 6
	snd_tie
	snd_len 1
	snd_note F_3, 4
	snd_note G_2, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note B_2, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note D_3, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note E_3, 6
	snd_tie
	snd_len 1
	snd_note D_3, 4
	snd_note G_2, 6
	snd_tie
	snd_len 1
	snd_note G_3, 4
	snd_note B_2, 6
	snd_tie
	snd_len 1
	snd_note B_3, 4
	snd_note D_3, 6
	snd_tie
	snd_len 1
	snd_note D_4, 4
	snd_note G_3, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_jump Trk_4CC0
	snd_end	; unreachable
Mus01_Ch1:
	snd_note REST, 15
	snd_note REST, 13
	snd_inst $00
	snd_env $94
	snd_pan $03
	snd_vibrato $00
	snd_sweep $08
	snd_duty $00
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
Trk_4EBE:
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 9
	snd_tie
	snd_len 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note G_4, 9
	snd_tie
	snd_len 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note As_4, 4
	snd_len 15
	snd_note A_4, 10
	snd_tie
	snd_len 1
	snd_note C_5, 9
	snd_note A_4
	snd_note C_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note F_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note A_4, 9
	snd_tie
	snd_len 4
	snd_note G_5, 9
	snd_len 9
	snd_len 6
	snd_tie
	snd_len 1
	snd_note Fs_5, 9
	snd_note F_5, 4
	snd_note E_5, 15
	snd_note A_4, 10
	snd_tie
	snd_len 1
	snd_note C_5, 9
	snd_note A_4
	snd_note C_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note F_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note A_4, 9
	snd_tie
	snd_len 4
	snd_note Ds_5, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note F_5, 6
	snd_tie
	snd_len 1
	snd_note Fs_5, 4
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_len 13
	snd_len 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 9
	snd_tie
	snd_len 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note G_4, 9
	snd_tie
	snd_len 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note As_4, 4
	snd_len 15
	snd_note A_4, 10
	snd_tie
	snd_len 1
	snd_note C_5, 9
	snd_note A_4
	snd_note C_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note F_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note A_4, 9
	snd_tie
	snd_len 4
	snd_note G_5, 9
	snd_len 9
	snd_len 6
	snd_tie
	snd_len 1
	snd_note Fs_5, 9
	snd_note F_5, 4
	snd_note E_5, 15
	snd_note A_4, 10
	snd_tie
	snd_len 1
	snd_note C_5, 9
	snd_note A_4
	snd_note C_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note F_5, 4
	snd_note E_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note A_4, 9
	snd_tie
	snd_len 4
	snd_note Ds_5, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note F_5, 6
	snd_tie
	snd_len 1
	snd_note Fs_5, 4
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_len 15
	snd_note E_5, 9
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note E_5, 9
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_4, 12
	snd_note C_5, 9
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note G_4, 1
	snd_note REST, 3
	snd_note C_5, 9
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note E_4, 12
	snd_note E_5, 9
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note E_5, 9
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note D_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note A_4, 12
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note G_4, 9
	snd_len 9
	snd_len 4
	snd_note A_4, 6
	snd_tie
	snd_len 1
	snd_note G_4, 4
	snd_note B_4, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_note B_4, 6
	snd_tie
	snd_len 1
	snd_note A_4, 4
	snd_note G_4, 9
	snd_note C_5, 6
	snd_tie
	snd_len 1
	snd_note D_5, 4
	snd_jump Trk_4EBE
	snd_end	; unreachable
Mus01_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $01
	snd_vibrato $01
	snd_note REST, 15
	snd_note REST
Trk_5090:
	snd_note REST
	snd_note REST
	snd_note REST
	snd_note REST, 9
	snd_note As_6, 4
	snd_note A_6, 3
	snd_note Gs_6, 4
	snd_note G_6, 12
	snd_note REST, 15
	snd_note REST, 15
	snd_note REST, 15
	snd_note REST, 6
	snd_tie
	snd_len 1
	snd_note E_7, 4
	snd_note Ds_7, 6
	snd_tie
	snd_len 1
	snd_note D_7, 4
	snd_note Cs_7, 6
	snd_tie
	snd_len 1
	snd_note C_7, 4
	snd_note B_6, 6
	snd_tie
	snd_len 1
	snd_note As_6, 4
	snd_note REST, 15
	snd_note REST, 15
	snd_note As_5, 6
	snd_tie
	snd_len 1
	snd_note B_5, 4
	snd_note C_6, 6
	snd_tie
	snd_len 1
	snd_note Cs_6, 4
	snd_note D_6, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note F_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_len 9
	snd_note E_7, 4
	snd_note Ds_7, 3
	snd_note D_7, 4
	snd_note C_7, 12
	snd_note REST, 15
	snd_note REST, 15
	snd_note REST, 15
	snd_note REST, 9
	snd_note As_6, 4
	snd_note A_6, 3
	snd_note Gs_6, 4
	snd_note G_6, 12
	snd_note REST, 15
	snd_note REST, 15
	snd_note REST, 15
	snd_note REST, 6
	snd_tie
	snd_len 1
	snd_note E_7, 4
	snd_note Ds_7, 6
	snd_tie
	snd_len 1
	snd_note D_7, 4
	snd_note Cs_7, 6
	snd_tie
	snd_len 1
	snd_note C_7, 4
	snd_note B_6, 6
	snd_tie
	snd_len 1
	snd_note As_6, 4
	snd_note REST, 15
	snd_note REST, 15
	snd_note As_5, 6
	snd_tie
	snd_len 1
	snd_note B_5, 4
	snd_note C_6, 6
	snd_tie
	snd_len 1
	snd_note Cs_6, 4
	snd_note D_6, 6
	snd_tie
	snd_len 1
	snd_note E_5, 4
	snd_note F_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_len 9
	snd_note E_7, 4
	snd_note Ds_7, 3
	snd_note D_7, 4
	snd_note C_7, 12
	snd_note A_4, 4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 1
	snd_note REST, 3
	snd_note G_4, 4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note A_4
	snd_note C_5, 3
	snd_note E_5, 4
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note A_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_len 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note A_5, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_note G_4, 9
	snd_note B_4
	snd_note D_5
	snd_note G_5
	snd_jump Trk_5090
	snd_end	; unreachable
Mus01_Ch4:
	snd_inst $00
	snd_env $81
	snd_pan $03
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B
	snd_note $12, 3
	snd_len 4
	snd_len 4
	snd_len 3
	snd_len 4
Trk_51F8:
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B
	snd_note $12, 3
	snd_len 4
	snd_len 4
	snd_len 3
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B
	snd_note $12, 3
	snd_len 4
	snd_len 4
	snd_len 3
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 1
	snd_note $0D, 3
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $12, 6
	snd_tie
	snd_len 1
	snd_len 4
	snd_note $0B
	snd_note $12, 3
	snd_len 4
	snd_len 4
	snd_len 3
	snd_len 4
	snd_jump Trk_51F8
	snd_end	; unreachable
Mus02_Ch2:
	snd_mastervol $FF
	snd_tempo $AA
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $04
Trk_5481:
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note D_3
	snd_note D_3, 6
	snd_len 6
	snd_len 6
	snd_note E_3
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_note D_3
	snd_note D_3, 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3, 12
	snd_len 6
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note D_3
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note E_3
	snd_note B_3
	snd_note E_4
	snd_note B_3
	snd_note F_3
	snd_note C_4
	snd_note F_4
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note D_3
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note E_3
	snd_note B_3
	snd_note E_4
	snd_note B_3
	snd_note F_3
	snd_note C_4
	snd_note F_4
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note D_3
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note E_3
	snd_note B_3
	snd_note E_4
	snd_note B_3
	snd_note F_3
	snd_note C_4
	snd_note F_4
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note D_3
	snd_note A_3
	snd_note D_4
	snd_note A_3
	snd_note G_3
	snd_note D_4
	snd_note G_4
	snd_note D_4
	snd_note C_3
	snd_note C_3, 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note A_2
	snd_note A_2, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note A_2
	snd_note A_2, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_jump Trk_5481
	snd_end	; unreachable
Mus02_Ch1:
	snd_inst $01
	snd_env $97
	snd_pan $03
	snd_vibrato $10
	snd_sweep $08
	snd_duty $C0
Trk_553E:
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note E_5
	snd_note F_5, 10
	snd_note E_5, 3
	snd_note F_5
	snd_note G_5, 10
	snd_len 3
	snd_note B_5
	snd_note C_6, 6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note E_5
	snd_note F_5, 10
	snd_note E_5, 3
	snd_note F_5
	snd_note G_5, 6
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note C_5, 12
	snd_len 10
	snd_note B_4, 3
	snd_note C_5
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note D_5
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note C_5
	snd_note A_4, 12
	snd_note C_5, 10
	snd_note B_4, 3
	snd_note C_5
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note D_5
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note E_5
	snd_note E_5, 6
	snd_note F_5
	snd_note B_5
	snd_note G_5
	snd_note C_5, 10
	snd_note B_4, 3
	snd_note C_5
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note D_5
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note C_5
	snd_note A_4, 12
	snd_note G_4, 10
	snd_note C_5, 3
	snd_note D_5
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note E_5
	snd_note G_5, 6
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note C_5, 12
	snd_note G_5, 9
	snd_note C_5, 13
	snd_note A_4, 9
	snd_note C_5, 10
	snd_len 6
	snd_note B_4
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note C_5, 12
	snd_tie
	snd_len 6
	snd_len 6
	snd_note B_4
	snd_note C_5
	snd_note G_5, 9
	snd_note C_5, 13
	snd_note A_4, 9
	snd_note C_5, 10
	snd_len 6
	snd_note B_4
	snd_note C_5
	snd_note E_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note C_5, 15
	snd_jump Trk_553E
	snd_end	; unreachable
Mus02_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $01
	snd_vibrato $04
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note A_3
	snd_note A_3, 6
	snd_len 6
	snd_len 6
	snd_note E_3
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note A_3
	snd_note A_3, 6
	snd_len 6
	snd_len 6
	snd_note E_3, 12
	snd_vibrato $01
	snd_inst $01
	snd_note G_6, 3
	snd_len 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_note G_6
	snd_note G_6, 3
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note E_6, 3
	snd_note C_6
	snd_note C_6, 3
	snd_vibrato $00
	snd_inst $01
	snd_note E_5, 9
	snd_note A_4, 13
	snd_note F_4, 9
	snd_note A_4, 13
	snd_note C_5, 6
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note B_4
	snd_note G_4
	snd_note G_4, 15
	snd_note E_5, 9
	snd_note A_4, 13
	snd_note F_4, 9
	snd_note A_4, 13
	snd_note C_5, 6
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note B_4
	snd_note G_4
	snd_note G_4, 15
	snd_jump Mus02_Ch3
	snd_end	; unreachable
Mus02_Ch4:
	snd_inst $00
	snd_env $81
	snd_pan $03
Trk_5700:
	snd_note $16, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_note $0B
	snd_note $16
	snd_note $12
	snd_note $16
	snd_jump Trk_5700
	snd_end	; unreachable
Mus04_Ch2:
	snd_mastervol $FF
	snd_tempo $AA
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $04
Trk_57B1:
	snd_note C_3, 6
	snd_len 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note F_3, 6
	snd_note G_3
	snd_note G_3, 6
	snd_note C_3
	snd_note Ds_3
	snd_note C_3
	snd_note Ds_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_4
	snd_note Ds_4
	snd_note F_4
	snd_note Fs_4
	snd_note F_4
	snd_note Ds_4
	snd_note C_4
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note F_3, 6
	snd_note G_3
	snd_note G_3, 6
	snd_note C_3
	snd_note Ds_3
	snd_note C_3
	snd_note Ds_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_3
	snd_note C_3, 6
	snd_note Ds_3
	snd_note Ds_3, 6
	snd_note F_3
	snd_note Fs_3
	snd_note F_3
	snd_note Fs_3
	snd_note C_4
	snd_note C_4, 6
	snd_note E_4
	snd_note F_4
	snd_note G_4
	snd_note F_4
	snd_note E_4
	snd_note C_4
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_jump Trk_57B1
	snd_end	; unreachable
Mus04_Ch1:
	snd_inst $00
	snd_env $94
	snd_pan $03
	snd_vibrato $00
	snd_sweep $08
	snd_duty $00
Trk_5906:
	snd_note REST, 15
	snd_note REST
	snd_note REST
	snd_note REST, 13
	snd_note C_5, 6
	snd_note Ds_5
	snd_note F_5, 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_5
	snd_note F_5
	snd_note Ds_5
	snd_note F_5
	snd_note Ds_5
	snd_note C_5
	snd_note As_4
	snd_note C_5, 9
	snd_len 6
	snd_note Ds_5
	snd_note F_5, 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_5
	snd_note F_5
	snd_note Ds_5
	snd_note F_5
	snd_note G_5
	snd_note As_5
	snd_note C_6
	snd_note G_5, 9
	snd_note C_5, 6
	snd_note Ds_5
	snd_note F_5, 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_5
	snd_note F_5
	snd_note Ds_5
	snd_note F_5
	snd_note Ds_5
	snd_note C_5
	snd_note As_4
	snd_note C_5, 12
	snd_len 6
	snd_len 9
	snd_note G_4
	snd_note As_4, 6
	snd_note C_5
	snd_note As_4
	snd_note C_5, 13
	snd_len 6
	snd_note Ds_5
	snd_note F_5, 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_5
	snd_note F_5
	snd_note Ds_5
	snd_note F_5
	snd_note Ds_5
	snd_note C_5
	snd_note As_4
	snd_note C_5, 9
	snd_len 6
	snd_note Ds_5
	snd_note F_5, 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_5
	snd_note F_5
	snd_note Ds_5
	snd_note F_5
	snd_note G_5
	snd_note As_5
	snd_note C_6
	snd_note G_5, 9
	snd_note C_5, 6
	snd_note Ds_5
	snd_note F_5, 9
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_5
	snd_note F_5
	snd_note Ds_5
	snd_note F_5
	snd_note Ds_5
	snd_note C_5
	snd_note As_4
	snd_note C_5, 12
	snd_len 6
	snd_len 9
	snd_note G_4
	snd_note As_4, 6
	snd_note C_5
	snd_note As_4
	snd_note REST, 13
	snd_note C_5, 6
	snd_note E_5
	snd_note F_6, 10
	snd_note E_6, 3
	snd_note F_6
	snd_note G_6, 10
	snd_note E_6, 3
	snd_note D_6
	snd_note E_6, 7
	snd_note D_6
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note C_6, 3
	snd_note B_5
	snd_note C_6, 7
	snd_note D_6
	snd_note E_6, 12
	snd_tie
	snd_len 6
	snd_note F_6, 10
	snd_note E_6, 3
	snd_note F_6
	snd_note G_6, 10
	snd_note E_6, 3
	snd_note D_6
	snd_note E_6, 7
	snd_note D_6
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note C_6, 3
	snd_note B_5
	snd_note C_6, 7
	snd_note B_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_note F_6, 10
	snd_note E_6, 3
	snd_note F_6
	snd_note G_6, 10
	snd_note E_6, 3
	snd_note D_6
	snd_note E_6, 7
	snd_note D_6
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note C_6, 3
	snd_note B_5
	snd_note C_6, 7
	snd_note D_6
	snd_note E_6, 12
	snd_tie
	snd_len 6
	snd_note F_6, 10
	snd_note E_6, 3
	snd_note F_6
	snd_note G_6, 10
	snd_note E_6, 3
	snd_note D_6
	snd_note E_6, 7
	snd_note D_6
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note C_6, 3
	snd_note B_5
	snd_note C_6, 7
	snd_note B_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_jump Trk_5906
	snd_end	; unreachable
Mus04_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $02
	snd_vibrato $01
	snd_note REST, 15
	snd_note REST
	snd_note REST
	snd_note REST
	snd_note C_7, 6
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note F_6
	snd_note As_6
	snd_note C_7
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note C_7
	snd_note G_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note C_7, 15
	snd_len 6
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note F_6
	snd_note As_6
	snd_note C_7
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note C_7
	snd_note G_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note C_7
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note Ds_6
	snd_note F_6
	snd_note Ds_6
	snd_note C_6
	snd_note C_7, 15
	snd_inst $02
	snd_vibrato $00
	snd_note C_6, 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note D_6, 3
	snd_note C_6
	snd_note C_6, 7
	snd_note B_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note G_5, 3
	snd_note A_5
	snd_note C_6, 10
	snd_note A_5, 3
	snd_note G_5
	snd_note A_5, 7
	snd_note B_5
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note D_6, 3
	snd_note C_6
	snd_note C_6, 7
	snd_note B_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note G_5, 3
	snd_note A_5
	snd_note C_6, 10
	snd_note A_5, 3
	snd_note G_5
	snd_note A_5, 7
	snd_note G_5
	snd_note E_5, 12
	snd_tie
	snd_len 6
	snd_note C_6, 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note D_6, 3
	snd_note C_6
	snd_note C_6, 7
	snd_note B_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note G_5, 3
	snd_note A_5
	snd_note C_6, 10
	snd_note A_5, 3
	snd_note G_5
	snd_note A_5, 7
	snd_note B_5
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note B_5, 3
	snd_note C_6
	snd_note E_6, 10
	snd_note D_6, 3
	snd_note C_6
	snd_note C_6, 7
	snd_note B_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_len 10
	snd_note G_5, 3
	snd_note A_5
	snd_note C_6, 10
	snd_note A_5, 3
	snd_note G_5
	snd_note A_5, 7
	snd_note G_5
	snd_note E_5, 12
	snd_tie
	snd_len 6
	snd_jump Mus04_Ch3
	snd_end	; unreachable
Mus04_Ch4:
	snd_inst $00
	snd_env $81
	snd_pan $03
Trk_5B1E:
	snd_note $0B, 9
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_len 15
	snd_note $0B, 9
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_len 15
	snd_note $0B, 9
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_jump Trk_5B1E
	snd_end	; unreachable
Mus03_Ch2:
	snd_mastervol $FF
	snd_tempo $B2
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $13
	snd_note REST, 15
	snd_note REST
Trk_5C24:
	snd_note C_3, 6
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note E_3
	snd_note E_4
	snd_note E_3
	snd_note E_4
	snd_note F_3
	snd_note F_4
	snd_note F_3
	snd_note F_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note E_3
	snd_note E_4
	snd_note E_3
	snd_note E_4
	snd_note F_3
	snd_note F_4
	snd_note F_3
	snd_note F_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note E_3
	snd_note E_4
	snd_note E_3
	snd_note E_4
	snd_note F_3
	snd_note F_4
	snd_note F_3
	snd_note F_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note E_3
	snd_note E_4
	snd_note E_3
	snd_note E_4
	snd_note F_3
	snd_note F_4
	snd_note F_3
	snd_note F_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_3, 15
	snd_len 6
	snd_note C_4
	snd_note G_2
	snd_note G_3
	snd_note C_3
	snd_note C_4
	snd_note G_2
	snd_note G_3
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note F_3
	snd_note F_4
	snd_note F_3
	snd_note F_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note F_3
	snd_note F_4
	snd_note F_3
	snd_note F_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note F_3
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note C_3, 6
	snd_note G_3, 3
	snd_note C_4
	snd_note E_3, 6
	snd_note C_4, 3
	snd_note E_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note F_3, 6
	snd_note C_4, 3
	snd_note F_4
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_note G_2, 6
	snd_note D_3, 3
	snd_note G_3
	snd_jump Trk_5C24
	snd_end	; unreachable
Mus03_Ch1:
	snd_inst $00
	snd_env $96
	snd_pan $03
	snd_vibrato $00
	snd_sweep $08
	snd_duty $80
	snd_note REST, 15
	snd_note REST
Trk_5D61:
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note G_5, 12
	snd_note A_5, 4
	snd_note G_5, 3
	snd_note F_5, 4
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_len 13
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note G_5, 12
	snd_note A_5, 4
	snd_note G_5, 3
	snd_note F_5, 4
	snd_note G_5, 10
	snd_tie
	snd_len 1
	snd_note C_6, 4
	snd_len 6
	snd_note B_5
	snd_note A_5
	snd_note B_5
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note G_5, 12
	snd_note A_5, 4
	snd_note G_5, 3
	snd_note F_5, 4
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_len 13
	snd_note G_5, 6
	snd_tie
	snd_len 1
	snd_note C_5, 4
	snd_note G_5, 12
	snd_note A_5, 4
	snd_note G_5, 3
	snd_note F_5, 4
	snd_note G_5, 10
	snd_note C_6, 6
	snd_len 9
	snd_note D_6
	snd_note C_6, 15
	snd_note REST, 13
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_len 6
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note G_5, 9
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_note A_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note C_5, 9
	snd_len 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_len 6
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note G_5, 9
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_note A_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note C_5, 12
	snd_len 10
	snd_note B_4, 3
	snd_note C_5
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note B_4
	snd_note C_5, 7
	snd_note B_4
	snd_note A_4, 12
	snd_tie
	snd_len 6
	snd_note C_5, 10
	snd_note B_4, 3
	snd_note C_5
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note B_4
	snd_note C_5, 7
	snd_note D_5
	snd_note E_5, 12
	snd_tie
	snd_len 6
	snd_note C_5, 10
	snd_note B_4, 3
	snd_note C_5
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note B_4
	snd_note C_5, 7
	snd_note B_4
	snd_note A_4, 12
	snd_tie
	snd_len 6
	snd_note D_5, 10
	snd_note C_5, 3
	snd_note D_5
	snd_note E_5, 10
	snd_note D_5, 3
	snd_note C_5
	snd_note D_5, 9
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_jump Trk_5D61
	snd_end	; unreachable
Mus03_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $02
	snd_vibrato $00
	snd_note REST, 15
	snd_note REST
Trk_5E54:
	snd_note E_6, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_note E_6, 12
	snd_note F_6, 4
	snd_note E_6, 3
	snd_note D_6, 4
	snd_note G_7, 6
	snd_note A_7, 3
	snd_note G_7
	snd_note F_7, 6
	snd_note G_7, 3
	snd_note F_7
	snd_note E_7, 6
	snd_note F_7, 3
	snd_note E_7
	snd_note D_7, 6
	snd_note E_7, 3
	snd_note D_7
	snd_note E_6, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_note E_6, 12
	snd_note F_6, 4
	snd_note E_6, 3
	snd_note D_6, 4
	snd_note E_6, 10
	snd_tie
	snd_len 1
	snd_note A_6, 4
	snd_len 6
	snd_note G_6
	snd_note F_6
	snd_note G_6
	snd_note E_6, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_note E_6, 12
	snd_note F_6, 4
	snd_note E_6, 3
	snd_note D_6, 4
	snd_note G_7, 6
	snd_note A_7, 3
	snd_note G_7
	snd_note F_7, 6
	snd_note G_7, 3
	snd_note F_7
	snd_note E_7, 6
	snd_note F_7, 3
	snd_note E_7
	snd_note D_7, 6
	snd_note E_7, 3
	snd_note D_7
	snd_note E_6, 6
	snd_tie
	snd_len 1
	snd_note G_5, 4
	snd_note E_6, 12
	snd_note F_6, 4
	snd_note E_6, 3
	snd_note D_6, 4
	snd_note F_6, 6
	snd_note G_6, 3
	snd_note F_6
	snd_note E_6
	snd_note F_6
	snd_note G_6
	snd_note A_6
	snd_note C_7, 6
	snd_note D_7, 3
	snd_note C_7
	snd_note B_6
	snd_note C_7
	snd_note D_7
	snd_note E_7
	snd_note E_6, 15
	snd_inst $03
	snd_vibrato $03
	snd_note REST, 15
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_len 6
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note G_5, 9
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_note A_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note C_5, 9
	snd_len 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_len 6
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note G_5, 9
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_len 7
	snd_note E_5, 3
	snd_note C_5, 9
	snd_note A_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note C_5, 12
	snd_inst $02
	snd_vibrato $12
	snd_note A_4, 10
	snd_note G_4, 3
	snd_note A_4
	snd_note B_4, 10
	snd_note A_4, 3
	snd_note G_4
	snd_note A_4, 7
	snd_note G_4
	snd_note F_4, 12
	snd_tie
	snd_len 6
	snd_note A_4, 10
	snd_note G_4, 3
	snd_note A_4
	snd_note B_4, 10
	snd_note A_4, 3
	snd_note G_4
	snd_note A_4, 7
	snd_note B_4
	snd_note C_5, 12
	snd_tie
	snd_len 6
	snd_note A_4, 10
	snd_note G_4, 3
	snd_note A_4
	snd_note B_4, 10
	snd_note A_4, 3
	snd_note G_4
	snd_note A_4, 7
	snd_note G_4
	snd_note F_4, 12
	snd_tie
	snd_len 6
	snd_note B_4, 10
	snd_note A_4, 3
	snd_note B_4
	snd_note C_5, 10
	snd_note B_4, 3
	snd_note A_4
	snd_note B_4, 9
	snd_note C_5
	snd_note D_5
	snd_note E_5
	snd_jump Trk_5E54
	snd_end	; unreachable
Mus03_Ch4:
	snd_inst $00
	snd_env $81
	snd_pan $03
	snd_note $12, 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
Trk_5F9B:
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 9
	snd_len 9
	snd_note $0B
	snd_note $0B, 9
	snd_len 9
	snd_note $12, 3
	snd_len 3
	snd_len 3
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_note $0D, 6
	snd_note $12, 6
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 7
	snd_len 6
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 3
	snd_len 3
	snd_len 3
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 1
	snd_len 3
	snd_jump Trk_5F9B
	snd_end	; unreachable
Mus05_Ch2:
	snd_mastervol $FF
	snd_tempo $BA
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $04
Trk_619D:
	snd_note C_3, 9
	snd_note C_4
	snd_note C_4, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note C_3
	snd_note C_4
	snd_note C_4, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note C_3
	snd_note C_4
	snd_note C_4, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note F_2
	snd_note F_3
	snd_note F_3, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note C_3
	snd_note C_4
	snd_note C_4, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note C_3
	snd_note C_4
	snd_note C_4, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note C_3
	snd_note C_4
	snd_note C_4, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note F_2
	snd_note F_3
	snd_note F_3, 9
	snd_note G_2
	snd_note G_3
	snd_note G_3, 9
	snd_note F_2, 6
	snd_note C_3
	snd_note F_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note A_2, 6
	snd_note C_4
	snd_note B_3
	snd_note A_3
	snd_note G_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note A_2, 6
	snd_note C_4
	snd_note B_3
	snd_note A_3
	snd_note G_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note A_2
	snd_note E_3
	snd_note A_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note F_2
	snd_note C_3
	snd_note F_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note G_2
	snd_note D_3
	snd_note G_3
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_jump Trk_619D
	snd_end	; unreachable
Mus05_Ch1:
	snd_inst $00
	snd_env $96
	snd_pan $03
	snd_vibrato $00
	snd_sweep $08
	snd_duty $00
Trk_6251:
	snd_note E_5, 13
	snd_note C_5
	snd_note G_4
	snd_note REST, 9
	snd_len 6
	snd_note C_5
	snd_note F_5
	snd_note A_5
	snd_note G_5, 13
	snd_note E_5, 12
	snd_tie
	snd_len 6
	snd_note C_5, 6
	snd_note A_4, 13
	snd_note B_4, 9
	snd_note A_4
	snd_note G_4
	snd_note E_5, 13
	snd_note C_5
	snd_note G_4
	snd_note REST, 9
	snd_len 6
	snd_note C_5
	snd_note F_5
	snd_note A_5
	snd_note G_5, 13
	snd_note E_5, 12
	snd_tie
	snd_len 6
	snd_note C_5, 6
	snd_note A_4, 13
	snd_note B_4, 9
	snd_note A_4
	snd_note G_4
	snd_note E_5, 10
	snd_note F_5, 6
	snd_note E_5, 9
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5, 10
	snd_note E_5, 6
	snd_note D_5, 9
	snd_note E_5, 13
	snd_note C_5, 10
	snd_note B_4, 6
	snd_note C_5, 9
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note C_5, 13
	snd_note E_5, 10
	snd_note F_5, 6
	snd_note E_5, 9
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5, 10
	snd_note E_5, 6
	snd_note D_5, 9
	snd_note E_5, 13
	snd_note C_5, 10
	snd_note B_4, 6
	snd_note C_5, 9
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note C_5, 13
	snd_jump Trk_6251
	snd_end	; unreachable
Mus05_Ch3:
	snd_env $20
	snd_pan $03
Trk_62C7:
	snd_inst $01
	snd_vibrato $01
	snd_note G_7, 6
	snd_note Fs_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note E_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note C_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note D_7
	snd_note E_7
	snd_note D_7
	snd_note C_7
	snd_note B_6
	snd_note A_6
	snd_note G_6
	snd_note G_7
	snd_note Fs_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note E_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note C_7
	snd_note F_6
	snd_note A_6
	snd_note C_7
	snd_note D_7
	snd_note E_7
	snd_note C_7
	snd_note G_6
	snd_note B_6
	snd_note C_7
	snd_note E_7
	snd_note F_7
	snd_note G_7
	snd_note G_7, 6
	snd_note Fs_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note E_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note C_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note D_7
	snd_note E_7
	snd_note D_7
	snd_note C_7
	snd_note B_6
	snd_note A_6
	snd_note G_6
	snd_note G_7
	snd_note Fs_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note E_7
	snd_note F_7
	snd_note E_7
	snd_note Ds_7
	snd_note D_7
	snd_note Cs_7
	snd_note C_7
	snd_note F_6
	snd_note A_6
	snd_note C_7
	snd_note D_7
	snd_note E_7
	snd_note C_7
	snd_note G_6
	snd_note B_6
	snd_note C_7
	snd_note E_7
	snd_note F_7
	snd_note G_7
	snd_inst $01
	snd_vibrato $00
	snd_note C_5, 10
	snd_note D_5, 6
	snd_note C_5, 9
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note B_4, 10
	snd_note C_5, 6
	snd_note B_4, 9
	snd_note C_5, 13
	snd_note A_4, 10
	snd_note G_4, 6
	snd_note A_4, 9
	snd_note B_4
	snd_note A_4
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note A_4, 13
	snd_note C_5, 10
	snd_note D_5, 6
	snd_note C_5, 9
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note B_4, 10
	snd_note C_5, 6
	snd_note B_4, 9
	snd_note C_5, 13
	snd_note A_4, 10
	snd_note G_4, 6
	snd_note A_4, 9
	snd_note B_4
	snd_note A_4
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note G_4, 13
	snd_jump Trk_62C7
	snd_end	; unreachable
Mus05_Ch4:
	snd_inst $00
	snd_env $81
	snd_pan $03
Trk_6379:
	snd_note $0B, 9
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $12, 9
	snd_jump Trk_6379
	snd_end	; unreachable
Mus06_Ch2:
	snd_mastervol $FF
	snd_tempo $BB
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $04
Trk_640A:
	snd_note C_3, 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_note F_3
	snd_note F_3, 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 9
	snd_len 6
	snd_note G_3, 9
	snd_note C_3, 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_note F_3
	snd_note F_3, 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 6
	snd_len 6
	snd_len 9
	snd_len 9
	snd_len 6
	snd_note G_3, 9
	snd_note A_2, 6
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note A_2
	snd_note A_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note F_2
	snd_note F_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note G_2
	snd_note G_3
	snd_note F_3
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note C_3, 6
	snd_note C_4, 3
	snd_note C_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note F_3, 6
	snd_note F_4, 3
	snd_note F_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_note G_3, 6
	snd_note G_4, 3
	snd_note G_3
	snd_jump Trk_640A
	snd_end	; unreachable
Mus06_Ch1:
	snd_inst $00
	snd_env $96
	snd_pan $03
	snd_vibrato $00
Trk_657A:
	snd_note E_5, 9
	snd_note D_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_note E_5, 6
	snd_note D_5
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note A_4, 9
	snd_note G_4, 6
	snd_note A_4
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note A_4
	snd_note C_5, 12
	snd_tie
	snd_len 6
	snd_note REST, 15
	snd_note E_5, 9
	snd_note D_5, 6
	snd_note E_5
	snd_note G_5, 9
	snd_note E_5, 6
	snd_note D_5
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note A_4, 9
	snd_note G_4, 6
	snd_note A_4
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note A_4
	snd_note C_5, 12
	snd_tie
	snd_len 6
	snd_note REST, 15
	snd_note E_5, 10
	snd_note F_5, 9
	snd_note E_5
	snd_note F_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5, 9
	snd_note E_5, 10
	snd_note C_5
	snd_note D_5, 9
	snd_note C_5
	snd_note D_5, 6
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note D_5, 10
	snd_note E_5
	snd_note F_5, 9
	snd_note E_5
	snd_note F_5, 6
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note D_5, 9
	snd_note E_5, 10
	snd_note C_5
	snd_note D_5, 9
	snd_note C_5
	snd_note D_5, 6
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note D_5, 10
	snd_note B_5
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_note B_5, 6
	snd_note C_6, 9
	snd_note E_6
	snd_note D_6, 6
	snd_note C_6
	snd_note B_5
	snd_note B_5, 10
	snd_note C_6, 9
	snd_note B_5
	snd_note C_6, 6
	snd_len 6
	snd_note D_6, 9
	snd_note E_6, 12
	snd_tie
	snd_len 6
	snd_note B_5, 10
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_note B_5, 6
	snd_note C_6, 9
	snd_note E_6
	snd_note D_6, 6
	snd_note C_6
	snd_note B_5
	snd_note B_5, 10
	snd_note C_6, 9
	snd_note B_5
	snd_note C_6, 6
	snd_note E_6
	snd_note D_6
	snd_note C_6
	snd_note B_5
	snd_note C_6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note B_5, 10
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_note B_5, 6
	snd_note C_6, 9
	snd_note E_6
	snd_note D_6, 6
	snd_note C_6
	snd_note B_5
	snd_note B_5, 10
	snd_note C_6, 9
	snd_note B_5
	snd_note C_6, 6
	snd_len 6
	snd_note D_6, 9
	snd_note E_6, 12
	snd_tie
	snd_len 6
	snd_jump Trk_657A
	snd_end	; unreachable
Mus06_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $01
	snd_vibrato $01
	snd_note E_3, 6
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note E_3
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note F_3
	snd_note A_3
	snd_note C_4
	snd_note F_3
	snd_note A_3
	snd_note C_4
	snd_note F_3
	snd_note A_3
	snd_note A_3, 6
	snd_len 9
	snd_len 9
	snd_len 6
	snd_note B_3, 9
	snd_note E_3, 6
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note E_3
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note C_4
	snd_note E_3
	snd_note G_3
	snd_note F_3
	snd_note A_3
	snd_note C_4
	snd_note F_3
	snd_note A_3
	snd_note C_4
	snd_note F_3
	snd_note A_3
	snd_note A_3, 6
	snd_len 9
	snd_len 9
	snd_len 6
	snd_note B_3, 9
	snd_inst $01
	snd_vibrato $00
	snd_note C_5, 10
	snd_note D_5, 9
	snd_note C_5
	snd_note D_5, 6
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note B_4, 9
	snd_note C_5, 10
	snd_note A_4
	snd_note B_4, 9
	snd_note A_4
	snd_note B_4, 6
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note B_4
	snd_note A_4
	snd_note B_4, 10
	snd_note C_5
	snd_note D_5, 9
	snd_note C_5
	snd_note D_5, 6
	snd_note E_5
	snd_note D_5
	snd_note C_5
	snd_note B_4, 9
	snd_note C_5, 10
	snd_note A_4
	snd_note B_4, 9
	snd_note A_4
	snd_note B_4, 6
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note B_4
	snd_note A_4
	snd_note B_4, 10
	snd_note G_5
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_note G_5, 6
	snd_note A_5, 9
	snd_note C_6
	snd_note B_5, 6
	snd_note A_5
	snd_note G_5
	snd_note G_5, 10
	snd_note A_5, 9
	snd_note G_5
	snd_note A_5, 6
	snd_len 6
	snd_note B_5, 9
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_note G_5, 10
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_note G_5, 6
	snd_note A_5, 9
	snd_note C_6
	snd_note B_5, 6
	snd_note A_5
	snd_note G_5
	snd_note G_5, 10
	snd_note A_5, 9
	snd_note G_5
	snd_note A_5, 6
	snd_note C_6
	snd_note B_5
	snd_note A_5
	snd_note G_5
	snd_note A_5
	snd_note G_5
	snd_note F_5
	snd_note E_5
	snd_note G_5, 10
	snd_note A_5, 12
	snd_tie
	snd_len 6
	snd_note G_5, 6
	snd_note A_5, 9
	snd_note C_6
	snd_note B_5, 6
	snd_note A_5
	snd_note G_5
	snd_note G_5, 10
	snd_note A_5, 9
	snd_note G_5
	snd_note A_5, 6
	snd_len 6
	snd_note B_5, 9
	snd_note C_6, 12
	snd_tie
	snd_len 6
	snd_jump Mus06_Ch3
	snd_end	; unreachable
Mus06_Ch4:
	snd_inst $00
	snd_env $81
	snd_pan $03
	snd_note $0B, 9
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_len 6
	snd_len 9
	snd_len 9
	snd_len 6
	snd_len 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_len 6
	snd_len 9
	snd_len 9
	snd_len 6
	snd_len 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B
	snd_note $12
	snd_note $0B, 6
	snd_len 6
	snd_note $12, 9
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_note $0B, 6
	snd_note $16, 3
	snd_len 3
	snd_note $12, 6
	snd_note $16, 3
	snd_len 3
	snd_jump Mus06_Ch4
	snd_end	; unreachable
Mus07_Ch2:
	snd_mastervol $FF
	snd_tempo $98
	snd_inst $00
	snd_env $86
	snd_pan $03
	snd_vibrato $11
Trk_6891:
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_2
	snd_note G_2, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_note E_3
	snd_note E_3, 6
	snd_note D_3
	snd_note D_3, 6
	snd_note C_3
	snd_note C_3, 6
	snd_note G_2
	snd_note G_2, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note A_2, 3
	snd_note G_2
	snd_note G_2, 3
	snd_note A_2
	snd_note B_2, 6
	snd_note C_3
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_2
	snd_note G_2, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_note E_3
	snd_note E_3, 6
	snd_note D_3
	snd_note D_3, 6
	snd_note C_3
	snd_note C_3, 6
	snd_note G_2
	snd_note G_2, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note A_2, 3
	snd_note G_2
	snd_note G_2, 3
	snd_note A_2
	snd_note B_2, 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note C_4
	snd_note C_4, 6
	snd_note B_3
	snd_note B_3, 6
	snd_note A_3
	snd_note A_3, 6
	snd_note G_3
	snd_note G_3, 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note C_4
	snd_note G_3
	snd_note A_3, 3
	snd_note G_3
	snd_note F_3, 6
	snd_note C_3, 12
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note E_3
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3
	snd_note D_3
	snd_note E_3
	snd_note E_3, 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note C_4
	snd_note C_4, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note D_4
	snd_note E_4, 9
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note E_3
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3
	snd_note D_3
	snd_note E_3
	snd_note E_3, 6
	snd_note F_3
	snd_note F_3, 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_note C_3
	snd_note C_3, 6
	snd_len 6
	snd_len 6
	snd_len 12
	snd_jump Trk_6891
Mus07_Ch1:
	snd_inst $01
	snd_env $97
	snd_pan $03
	snd_vibrato $10
	snd_sweep $08
	snd_duty $C0
Trk_697C:
	snd_note E_6, 9
	snd_note C_6
	snd_note D_6
	snd_note G_5
	snd_note E_6
	snd_note C_6
	snd_note D_6
	snd_note G_5
	snd_note E_6, 10
	snd_len 3
	snd_note F_6
	snd_note G_6, 6
	snd_note F_6
	snd_note E_6
	snd_note E_6, 3
	snd_note F_6
	snd_note D_6, 10
	snd_len 3
	snd_note E_6
	snd_note F_6, 6
	snd_note E_6
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note A_5
	snd_note B_5
	snd_note C_6
	snd_note A_5
	snd_note G_5
	snd_note B_5
	snd_note C_6
	snd_note G_5
	snd_note F_5
	snd_note B_5
	snd_note C_6
	snd_note D_6
	snd_note F_6
	snd_note E_6
	snd_note D_6
	snd_note C_6
	snd_note C_6, 10
	snd_len 2
	snd_note D_6
	snd_note C_6
	snd_note B_5, 9
	snd_note G_5
	snd_note E_6, 10
	snd_len 3
	snd_note F_6
	snd_note G_6, 6
	snd_note F_6
	snd_note E_6
	snd_note E_6, 3
	snd_note F_6
	snd_note D_6, 10
	snd_len 3
	snd_note E_6
	snd_note F_6, 6
	snd_note E_6
	snd_note D_6
	snd_note D_6, 3
	snd_note E_6
	snd_note A_5
	snd_note B_5
	snd_note C_6
	snd_note A_5
	snd_note G_5
	snd_note B_5
	snd_note C_6
	snd_note G_5
	snd_note F_5
	snd_note B_5
	snd_note C_6
	snd_note D_6
	snd_note F_6
	snd_note E_6
	snd_note D_6
	snd_note C_6
	snd_note C_6, 10
	snd_len 2
	snd_note D_6
	snd_note C_6
	snd_note B_5, 9
	snd_note G_5
	snd_note A_5, 6
	snd_len 6
	snd_len 3
	snd_note G_5
	snd_note A_5
	snd_note B_5
	snd_note C_6, 6
	snd_len 6
	snd_len 3
	snd_note B_5
	snd_note C_6
	snd_note D_6
	snd_note E_6, 6
	snd_note C_6
	snd_note D_6, 3
	snd_note C_6
	snd_note B_5, 6
	snd_note C_6
	snd_note B_5
	snd_note A_5, 3
	snd_note B_5
	snd_note G_5, 6
	snd_note A_5
	snd_note A_5, 6
	snd_len 2
	snd_note B_5
	snd_note A_5
	snd_note G_5, 3
	snd_note A_5
	snd_note B_5, 6
	snd_len 6
	snd_len 2
	snd_note C_6
	snd_note B_5
	snd_note A_5, 3
	snd_note B_5
	snd_note C_6, 6
	snd_note G_5
	snd_note A_5, 3
	snd_note G_5
	snd_note F_5, 6
	snd_note E_5, 12
	snd_note D_5, 9
	snd_note G_5
	snd_note F_5, 6
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note C_5, 9
	snd_note G_4
	snd_note G_5
	snd_note C_5
	snd_note A_4
	snd_note F_5
	snd_note E_5, 6
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note C_5, 9
	snd_note G_4
	snd_note G_5
	snd_note C_5
	snd_note D_5
	snd_note G_5
	snd_note F_5, 6
	snd_note E_5
	snd_note D_5
	snd_note E_5
	snd_note C_5, 9
	snd_note G_4
	snd_note G_5
	snd_note C_5
	snd_note A_4
	snd_note F_5
	snd_note E_5, 6
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note C_5, 12
	snd_jump Trk_697C
Mus07_Ch3:
	snd_env $20
	snd_pan $03
	snd_inst $02
Trk_6A55:
	snd_vibrato $11
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_vibrato $10
	snd_note A_5
	snd_note A_5, 6
	snd_note G_5
	snd_note G_5, 6
	snd_note F_5
	snd_note F_5, 6
	snd_note E_5
	snd_note E_5, 6
	snd_note G_5
	snd_note G_5, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 3
	snd_note A_5
	snd_note B_5, 6
	snd_vibrato $11
	snd_note E_3
	snd_note E_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_note G_3
	snd_note G_3, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_vibrato $10
	snd_note A_5
	snd_note A_5, 6
	snd_note G_5
	snd_note G_5, 6
	snd_note F_5
	snd_note F_5, 6
	snd_note E_5
	snd_note E_5, 6
	snd_note G_5
	snd_note G_5, 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 6
	snd_len 3
	snd_note A_5
	snd_note B_5, 6
	snd_note F_5
	snd_note F_5, 6
	snd_len 3
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note A_5, 6
	snd_len 6
	snd_len 3
	snd_note G_5
	snd_note A_5
	snd_note B_5
	snd_note C_5
	snd_note G_5
	snd_note C_6
	snd_note G_5
	snd_note B_4
	snd_note F_5
	snd_note B_5
	snd_note F_5
	snd_note A_4
	snd_note E_5
	snd_note A_5
	snd_note E_5
	snd_note G_4
	snd_note D_5
	snd_note G_5
	snd_note D_5
	snd_note F_5, 6
	snd_len 6
	snd_len 2
	snd_note G_5
	snd_note F_5
	snd_note E_5, 3
	snd_note F_5
	snd_note G_5, 6
	snd_len 6
	snd_len 2
	snd_note A_5
	snd_note G_5
	snd_note F_5, 3
	snd_note G_5
	snd_note A_5, 6
	snd_note E_5
	snd_note F_5, 3
	snd_note E_5
	snd_note D_5, 6
	snd_note C_5, 12
	snd_note G_4, 6
	snd_note B_4
	snd_note C_5
	snd_note G_4
	snd_note F_4
	snd_note B_4
	snd_note C_5
	snd_note F_4
	snd_note E_4
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note E_5, 9
	snd_note F_4, 6
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_note G_4
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5
	snd_note C_6
	snd_note E_6
	snd_note G_6
	snd_note C_7, 9
	snd_note G_4, 6
	snd_note B_4
	snd_note C_5
	snd_note G_4
	snd_note F_4
	snd_note B_4
	snd_note C_5
	snd_note F_4
	snd_note E_4
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note E_5, 9
	snd_note F_4, 6
	snd_note B_4
	snd_note C_5
	snd_note B_4
	snd_note G_4
	snd_note C_5
	snd_note D_5
	snd_note C_5
	snd_note C_5, 6
	snd_note E_5
	snd_note G_5
	snd_note C_6
	snd_note E_6
	snd_note G_6
	snd_note C_7, 9
	snd_jump Trk_6A55
Mus07_Ch4:
	snd_end
SndUnused_6B43:
	snd_note $0D, 15
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_note $0D
	snd_end
SndSfxTable:
	dw Sfx08, Sfx09, Sfx0A, Sfx0B, Sfx0C, Sfx0D, Sfx0E, Sfx0F
	dw Sfx10, Sfx11, Sfx12, Sfx13, Sfx14, Sfx15, Sfx16, Sfx17
	dw Sfx18, Sfx19, Sfx1A, Sfx1B, Sfx1C, Sfx1D, Sfx1E, Sfx1F
	dw Sfx20
Sfx08:
	dw Sfx08_Ch2, Sfx08_Ch4
Sfx09:
	dw Sfx09_Ch2, Sfx09_Ch4
Sfx0A:
	dw Sfx0A_Ch2, Sfx09_Ch4
Sfx0B:
	dw Sfx0B_Ch2, Sfx09_Ch4
Sfx0C:
	dw Sfx0C_Ch2, Sfx0C_Ch4
Sfx0D:
	dw Sfx0D_Ch2, Sfx09_Ch4
Sfx0E:
	dw Sfx09_Ch4, Sfx0E_Ch4
Sfx0F:
	dw Sfx0F_Ch2, Sfx09_Ch4
Sfx10:
	dw Sfx10_Ch2, Sfx10_Ch4
Sfx11:
	dw Sfx11_Ch2, Sfx09_Ch4
Sfx12:
	dw Sfx12_Ch2, Sfx09_Ch4
Sfx13:
	dw Sfx13_Ch2, Sfx09_Ch4
Sfx14:
	dw Sfx14_Ch2, Sfx09_Ch4
Sfx15:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx16:
	dw Sfx16_Ch2, Sfx09_Ch4
Sfx17:
	dw Sfx17_Ch2, Sfx09_Ch4
Sfx18:
	dw Sfx18_Ch2, Sfx09_Ch4
Sfx19:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx1A:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx1B:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx1C:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx1D:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx1E:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx1F:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx20:
	dw Sfx09_Ch4, Sfx09_Ch4
Sfx08_Ch2:
	snd_env $E1
	snd_pan $03
	snd_vibrato $05
	snd_inst $00
	snd_note A_4, 1
	snd_env $E2
	snd_note A_3, 3
	snd_end
Sfx08_Ch4:
	snd_end
SndUnused_6C01:
	snd_env $F1
	snd_note $00, 9
	snd_note $10
	snd_note $20
	snd_note $30
	snd_note $40
	snd_note $50
	snd_note $60
	snd_note $70
	snd_note $80
	snd_note $90
	snd_rawnote $A0
	snd_rawnote $B0
	snd_rawnote $C0
	snd_rawnote $D0
	snd_rawnote $E0
	snd_rawnote $F0
	snd_note $01
	snd_note $11
	snd_note $21
	snd_note $31
	snd_note $41
	snd_note $51
	snd_note $61
	snd_note $71
	snd_note $81
	snd_note $91
	snd_rawnote $A1
	snd_rawnote $B1
	snd_rawnote $C1
	snd_rawnote $D1
	snd_rawnote $E1
	snd_rawnote $F1
	snd_note $02
	snd_note $12
	snd_note $22
	snd_note $32
	snd_note $42
	snd_note $52
	snd_note $62
	snd_note $72
	snd_note $82
	snd_note $92
	snd_rawnote $A2
	snd_rawnote $B2
	snd_rawnote $C2
	snd_rawnote $D2
	snd_rawnote $E2
	snd_rawnote $F2
	snd_note $03
	snd_note $13
	snd_note $23
	snd_note $33
	snd_note $43
	snd_note $53
	snd_note $63
	snd_note $73
	snd_note $83
	snd_note $93
	snd_rawnote $A3
	snd_rawnote $B3
	snd_rawnote $C3
	snd_rawnote $D3
	snd_rawnote $E3
	snd_rawnote $F3
	snd_note $04
	snd_note $14
	snd_note $24
	snd_note $34
	snd_note $44
	snd_note $54
	snd_note $64
	snd_note $74
	snd_note $84
	snd_note $94
	snd_rawnote $A4
	snd_rawnote $B4
	snd_rawnote $C4
	snd_rawnote $D4
	snd_rawnote $E4
	snd_rawnote $F4
	snd_note $05
	snd_note $15
	snd_note $25
	snd_note $35
	snd_note $45
	snd_note $55
	snd_note $65
	snd_note $75
	snd_note $85
	snd_note $95
	snd_rawnote $A5
	snd_rawnote $B5
	snd_rawnote $C5
	snd_rawnote $D5
	snd_rawnote $E5
	snd_rawnote $F5
	snd_note $06
	snd_note $16
	snd_note $26
	snd_note $36
	snd_note $46
	snd_note $56
	snd_note $66
	snd_note $76
	snd_note $86
	snd_note $96
	snd_rawnote $A6
	snd_rawnote $B6
	snd_rawnote $C6
	snd_rawnote $D6
	snd_rawnote $E6
	snd_rawnote $F6
	snd_note $07
	snd_note $17
	snd_note $27
	snd_note $37
	snd_note $47
	snd_note $57
	snd_note $67
	snd_note $77
	snd_note $87
	snd_note $97
	snd_rawnote $A7
	snd_rawnote $B7
	snd_rawnote $C7
	snd_rawnote $D7
	snd_rawnote $E7
	snd_rawnote $F7
	snd_note $08
	snd_note $18
	snd_note $28
	snd_note $38
	snd_note $48
	snd_note $58
	snd_note $68
	snd_note $78
	snd_note $88
	snd_note $98
	snd_rawnote $A8
	snd_rawnote $B8
	snd_rawnote $C8
	snd_rawnote $D8
	snd_rawnote $E8
	snd_rawnote $F8
	snd_note $09
	snd_note $19
	snd_note $29
	snd_note $39
	snd_note $49
	snd_note $59
	snd_note $69
	snd_note $79
	snd_note $89
	snd_note $99
	snd_rawnote $A9
	snd_rawnote $B9
	snd_rawnote $C9
	snd_rawnote $D9
	snd_rawnote $E9
	snd_rawnote $F9
	snd_note $0A
	snd_note $1A
	snd_note $2A
	snd_note $3A
	snd_note $4A
	snd_note $5A
	snd_note $6A
	snd_note $7A
	snd_note $8A
	snd_note $9A
	snd_rawnote $AA
	snd_rawnote $BA
	snd_rawnote $CA
	snd_rawnote $DA
	snd_rawnote $EA
	snd_rawnote $FA
	snd_note $0B
	snd_note $1B
	snd_note $2B
	snd_note $3B
	snd_note $4B
	snd_note $5B
	snd_note $6B
	snd_note $7B
	snd_note $8B
	snd_note $9B
	snd_rawnote $AB
	snd_rawnote $BB
	snd_rawnote $CB
	snd_rawnote $DB
	snd_rawnote $EB
	snd_rawnote $FB
	snd_note $0C
	snd_note $1C
	snd_note $2C
	snd_note $3C
	snd_note $4C
	snd_note $5C
	snd_note $6C
	snd_note $7C
	snd_note $8C
	snd_note $9C
	snd_rawnote $AC
	snd_rawnote $BC
	snd_rawnote $CC
	snd_rawnote $DC
	snd_rawnote $EC
	snd_rawnote $FC
	snd_note $0D
	snd_note $1D
	snd_note $2D
	snd_note $3D
	snd_note $4D
	snd_note $5D
	snd_note $6D
	snd_note $7D
	snd_note $8D
	snd_note $9D
	snd_rawnote $AD
	snd_rawnote $BD
	snd_rawnote $CD
	snd_rawnote $DD
	snd_rawnote $ED
	snd_rawnote $FD
	snd_end
Sfx09_Ch2:
	snd_env $E0
	snd_pan $03
	snd_vibrato $0F
	snd_inst $00
	snd_note A_3, 6
	snd_end
Sfx0A_Ch2:
	snd_env $E0
	snd_pan $03
	snd_vibrato $0E
	snd_inst $00
	snd_note A_5, 6
	snd_end
Sfx0B_Ch2:
	snd_env $E0
	snd_pan $03
	snd_vibrato $09
	snd_inst $00
	snd_note C_4, 0
	snd_note Cs_4
	snd_note D_4
	snd_note Ds_4
	snd_note E_4
	snd_note F_4
	snd_note Fs_4
	snd_note G_4
	snd_note Gs_4
	snd_note A_4
	snd_note As_4
	snd_note B_4
	snd_end
Sfx0C_Ch2:
	snd_pan $03
	snd_vibrato $07
	snd_inst $00
	snd_env $D2
	snd_note F_5, 2
	snd_note E_4, 2
	snd_note REST, 2
	snd_note F_5, 2
	snd_note E_4, 2
	snd_end
Sfx0C_Ch4:
	snd_end
Sfx0D_Ch2:
	snd_env $E7
	snd_pan $03
	snd_vibrato $08
	snd_inst $00
	snd_note G_4, 15
	snd_end
Sfx0E_Ch4:
	snd_env $F1
	snd_pan $03
	snd_note $64, 0
	snd_end
Sfx0F_Ch2:
	snd_env $E0
	snd_pan $03
	snd_inst $00
	snd_vibrato $0A
	snd_note A_7, 3
	snd_end
Sfx10_Ch2:
	snd_end
Sfx10_Ch4:
	snd_env $F1
	snd_pan $03
	snd_rawnote $C4, 1
	snd_env $F3
	snd_rawnote $E4, 3
	snd_end
Sfx11_Ch2:
	snd_pan $03
	snd_inst $02
	snd_vibrato $0B
	snd_env $F4
	snd_note G_7, 5
	snd_slur
	snd_note Fs_7
	snd_slur
	snd_note F_7
	snd_slur
	snd_note E_7
	snd_slur
	snd_note Ds_7
	snd_slur
	snd_note E_7
	snd_env $F4
	snd_note F_7
	snd_slur
	snd_note E_7
	snd_slur
	snd_note Ds_7
	snd_slur
	snd_note D_7
	snd_slur
	snd_note Cs_7
	snd_slur
	snd_note C_7
	snd_end
Sfx12_Ch2:
	snd_env $F0
	snd_pan $03
	snd_vibrato $07
	snd_inst $00
	snd_note A_5, 3
	snd_end
Sfx13_Ch2:
	snd_env $D0
	snd_pan $03
	snd_vibrato $0C
	snd_inst $00
	snd_note A_3, 9
	snd_end
Sfx14_Ch2:
	snd_env $D0
	snd_pan $03
	snd_vibrato $0D
	snd_inst $00
	snd_note A_5, 15
	snd_tie
	snd_len 15
	snd_tie
	snd_len 15
	snd_tie
	snd_len 15
	snd_end
Sfx16_Ch2:
	snd_env $D0
	snd_pan $03
	snd_vibrato $0D
	snd_inst $02
	snd_note E_5, 2
	snd_slur
	snd_note F_5, 9
	snd_end
Sfx17_Ch2:
	snd_env $D0
	snd_pan $03
	snd_vibrato $00
	snd_inst $02
	snd_note E_3, 5
	snd_slur
	snd_note F_4, 9
	snd_end
Sfx18_Ch2:
	snd_env $D0
	snd_pan $03
	snd_vibrato $15
	snd_inst $01
	snd_note C_4, 2
	snd_note Cs_4
	snd_note D_4
	snd_note Ds_4
	snd_note E_4
	snd_note F_4
	snd_note Fs_4
	snd_note G_4
	snd_note A_4
	snd_end
Sfx09_Ch4:
	snd_end
