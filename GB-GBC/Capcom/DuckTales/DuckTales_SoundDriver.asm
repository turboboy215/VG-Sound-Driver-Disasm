; =============================================================================
; DuckTales (GB, Europe) [!] - sound driver, music and sound effects
; ROM: "Duck Tales (E) [!].gb", MBC1, 64 KB, bank 2 = sound bank
;
; Byte-exact disassembly. Rebuild check:
;   rgbasm -o dt.o DuckTales_SoundDriver.asm
;   rgblink -p 0xFF -o dt.gb dt.o      (then compare the ranges below)
; Ranges: 0:$0183-$0194, 0:$0212-$0220, 0:$0725-$0743,
;         2:$4026-$60F8 (driver, songs, SFX), 2:$615F-$6197 (stage music / request)
;
; A GB-specific driver whose music format follows Capcom's NES "Mega Man 2"
; engine (the one the NES DuckTales used): commands $00-$09, notes with a
; 3-bit length and 5-bit pitch, $2x "connect" bytes, $30 triplet prefix.
; All driver state lives in HRAM $FFA9-$FFFD. See DuckTales_SoundDriver.md.
; =============================================================================

; ---- hardware registers
DEF rROMB0         EQU $2000
DEF rNR10          EQU $FF10
DEF rNR11          EQU $FF11
DEF rNR12          EQU $FF12
DEF rNR13          EQU $FF13
DEF rNR14          EQU $FF14
DEF rNR21          EQU $FF16
DEF rNR22          EQU $FF17
DEF rNR23          EQU $FF18
DEF rNR24          EQU $FF19
DEF rNR30          EQU $FF1A
DEF rNR31          EQU $FF1B
DEF rNR32          EQU $FF1C
DEF rNR33          EQU $FF1D
DEF rNR34          EQU $FF1E
DEF rNR41          EQU $FF20
DEF rNR42          EQU $FF21
DEF rNR43          EQU $FF22
DEF rNR44          EQU $FF23
DEF rNR50          EQU $FF24
DEF rNR51          EQU $FF25
DEF rNR52          EQU $FF26
DEF _AUD3WAVERAM   EQU $FF30

; ---- HRAM used by the driver ($FFA9-$FFFD) and the game
DEF hJoyHeld       EQU $FF8C      ; game: buttons held
DEF hCurROMBank    EQU $FF93      ; game: current ROM bank
DEF hSndRequest    EQU $FFA9      ; request: $01-$3F SFX, $40|n song n, $80|n command n
DEF hMusicID       EQU $FFAA      ; current song (0 = none)
DEF hSfxID         EQU $FFAB      ; current SFX (0 = none)
DEF hMusTrigger    EQU $FFAC      ; NRx4 flag bits for the next music register write ($C0 = trigger+length, $80 = update)
DEF hTempoReload   EQU $FFAD      ; song tempo: a tick is skipped every N non-multiple-of-8 frames
DEF hTempoCounter  EQU $FFAE      
DEF hHalfLength    EQU $FFAF      ; song flag: nonzero halves every note length
DEF hMusPtr        EQU $FFB0      ; 4 x stream pointer (CH1..CH4)
DEF hVibTable      EQU $FFB8      ; pointer to the song's vibrato table
DEF hCurChan       EQU $FFBA      ; channel being processed (0-3)
DEF hCurByte       EQU $FFBB      ; last stream byte read
DEF hTripletFlag   EQU $FFBC      ; next note uses TripletLengths
DEF hTieCount      EQU $FFBD      ; notes left to merge (TIE)
DEF hNoteBase      EQU $FFBE      ; 3 x pointer into FreqTable (BASE), CH1..CH3
DEF hMusFreq       EQU $FFC6      ; 4 x current period (lo, hi)
DEF hMusVib        EQU $FFCE      ; 4 x (vibrato enable, vibrato phase)
DEF hLoopCount     EQU $FFD6      ; 4 x loop counter
DEF hMusDuty       EQU $FFDA      ; 4 x NRx1 upper bits (DUTY)
DEF hNoteTimer     EQU $FFDE      ; 4 x frames left in the current note
DEF hMusVolume     EQU $FFE2      ; 4 x NRx2 upper nibble (VOLUME)
DEF hMusEnvelope   EQU $FFE6      ; 4 x NRx2 lower nibble (ENVELOPE)
DEF hSfxMask       EQU $FFEA      ; SFX channel mask (bit0 CH1 .. bit3 CH4)
DEF hSfxChanLeft   EQU $FFEB      ; channels not yet given a note in this event group
DEF hSfxPtr        EQU $FFEC      ; SFX stream pointer
DEF hSfxTimer      EQU $FFEE      ; frames to wait before the next SFX event
DEF hSfxDuty       EQU $FFEF      ; SFX NRx1
DEF hSfxEnv        EQU $FFF0      ; SFX NRx2
DEF hSfxLoop       EQU $FFF1      ; SFX loop counter
DEF hSfxSlide      EQU $FFF2      ; SFX per-frame period slide (signed)
DEF hSfxOwn        EQU $FFF3      ; 4 x frames the SFX still owns the channel (music muted)
DEF hSfxFreq       EQU $FFF7      ; last SFX period written (lo, hi)
DEF hSfxLastFreq   EQU $FFF9      ; period of the last SFX note (for SREPEAT)
DEF hSfxVib        EQU $FFFB      ; SFX vibrato enable
DEF hSfxVibPhase   EQU $FFFC      ; SFX vibrato phase
DEF hSfxEndFlag    EQU $FFFD      ; set by SEND: stop when the timer runs out

; ---- game WRAM read by the sound code
DEF wFrameCounter  EQU $C620      ; game: VBlank frame counter (16-bit)
DEF wMenuVar1      EQU $C622      ; game
DEF wMenuVar2      EQU $C623      ; game
DEF wMenuVar3      EQU $C624      ; game
DEF wMenuVar4      EQU $C625      ; game
DEF wStage         EQU $C628      ; game: stage index (0-5)
DEF wMenuTable     EQU $C62A      ; game

; ---- game code outside the sound area
DEF MainLoop       EQU $0257
DEF SwitchToBank2  EQU $0337
DEF VBlank_Next    EQU $3765
DEF MenuCursor     EQU $60F9

; =============================================================================
; Music stream macros
; Note byte: bits 7-5 = length index, bits 4-0 = pitch (0 = rest).
; Pitch p plays FreqTable[BASE + p]; FreqTable[12] = C2.
; Length index -> ticks (NoteLengths; halved when the song's half flag is set):
DEF LTICK EQU 1   ; 1 tick
DEF L32   EQU 2   ; 3 ticks
DEF L16   EQU 3   ; 6
DEF L8    EQU 4   ; 12
DEF L4    EQU 5   ; 24
DEF L2    EQU 6   ; 48
DEF L1    EQU 7   ; 96
MACRO NOTE      ; length, pitch 1-31
	db ((\1) << 5) | (\2)
ENDM
MACRO REST      ; length
	db (\1) << 5
ENDM
MACRO DOTTED    ; length, pitch: 1.5x length
	db $06, ((\1) << 5) | (\2)
ENDM
MACRO DOTTED_REST
	db $06, (\1) << 5
ENDM
MACRO TIE       ; n = 2..16: merge the next n notes (lengths add, last pitch plays)
	db $1F + (\1)
ENDM
MACRO TRIPLET   ; next note uses TripletLengths
	db $30
ENDM
MACRO IGNORED   ; command $00/$01/$0A-$0F + argument, skipped by the driver
	db \1, \2
ENDM
MACRO DUTY      ; NRx1 bits 7-6 (CH3: NR31 base)
	db $02, \1
ENDM
MACRO VOLUME    ; NRx2 bits 7-4 (CH3: NR32 level)
	db $03, \1
ENDM
MACRO LOOP      ; count, label: jump back count times
	db $04, \1
	dw \2
ENDM
MACRO GOTO      ; label: jump forever
	db $04, $00
	dw \1
ENDM
MACRO BASE      ; FreqTable offset for pitch 0
	db $05, \1
ENDM
MACRO ENVELOPE  ; NRx2 bits 3-0 (direction, sweep)
	db $07, \1
ENDM
MACRO VIBRATO   ; index into the song's vibrato table
	db $08, \1
ENDM
MACRO MUS_END   ; stop the song
	db $09
ENDM

; =============================================================================
; SFX stream macros
MACRO SFX_CHANNELS  ; channel mask, bit0 = CH1 .. bit3 = CH4
	db \1
ENDM
MACRO SWAIT     ; frames
	db $00, \1
ENDM
MACRO SSLIDE    ; signed period change per frame (until the next event)
	db $01, LOW(\1)
ENDM
MACRO SDUTY     ; NRx1
	db $02, \1
ENDM
MACRO SENV      ; NRx2
	db $03, \1
ENDM
MACRO SLOOP     ; count (0 = forever), label
	db $04, \1
	dw \2
ENDM
MACRO SVIBRATO  ; bits 7-5 nonzero = on
	db $05, \1
ENDM
MACRO SEND
	db $06
ENDM
MACRO SNOTE     ; 11-bit period (CH4: NR43 = $30 | (period & 7)); goes to the next channel of the mask
	db $80 | HIGH(\1), LOW(\1)
ENDM
MACRO SREPEAT   ; hi >= $88: replay the previous period (second byte ignored)
	db \1, \2
ENDM

SECTION "DT Sound glue init", ROM0[$0183]

;; Called once at boot
GameSndInit:
	ld a, $02
	ld [rROMB0], a
	ldh [hCurROMBank], a
	call SndJT_Init
	ld a, $01
	ld [rROMB0], a
	ldh [hCurROMBank], a
	ret

SECTION "DT Sound glue VBlank", ROM0[$0212]

;; Inside the VBlank handler
VBlank_SndUpdate:
	ld a, $02
	ld [rROMB0], a
	call SndJT_Update
	ldh a, [hCurROMBank]
	ld [rROMB0], a
	ldh [hCurROMBank], a

SECTION "DT Sound glue requests", ROM0[$0725]

;; Stage start
GamePlayStageMusic:
	call SwitchToBank2
	jp SndJT_PlayStageMusic

;; A = request (see SndRequest). Preserves the ROM bank, BC and HL.
GamePlaySound:
	push hl
	push bc
	ld b, a
	ldh a, [hCurROMBank]
	push af
	ld a, $02
	ld [rROMB0], a
	ldh [hCurROMBank], a
	call SndJT_Request
	pop af
	ld [rROMB0], a
	ldh [hCurROMBank], a
	pop bc
	pop hl
	ret

SECTION "DT Sound driver and data", ROMX[$4026], BANK[2]

;; Entry points, called with bank 2 mapped. $402C is a menu routine, not sound.
SndJT_PlayStageMusic:
	jp SndPlayStageMusic
SndJT_Update:
	jp SndUpdate
SndJT_MenuCursor:
	jp MenuCursor
SndJT_Init:
	jp SndInit
SndJT_Request:
	jp SndRequest

;; SFX priority, indexed by SFX id ($00 unused). A new SFX starts only if
;; its priority is >= that of the SFX playing.
SfxPriority:
	db $10, $80, $50, $A0, $C0, $F0, $60, $D0, $B0, $C0, $50, $50, $50, $50, $50, $50, $50
	db $50, $50, $50, $50, $50, $C0, $90, $50, $50, $50, $50, $50, $50, $F0, $F0, $F0, $F0

;; SndInit: APU on, full volume, all channels routed to both outputs,
;; all four channels silenced (NRx2 = $08, triggered).
SndInit:
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $FF
	ldh [rNR51], a
	ld a, $08
	ldh [rNR10], a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ldh [rNR30], a
	xor a, a
	ldh [rNR32], a
	ret

;; SndUpdate: called once per frame from the VBlank handler.
;; A pending request is handled instead of the SFX/lock pass that frame.
SndUpdate:
	ldh a, [hSndRequest]
	and a, $3F
	jr nz, SndHandleRequest
	ldh a, [hSfxID]
	and a, a
	call nz, SfxUpdate
	ld hl, hSfxOwn                          ; CH1 locked by an SFX: count down, re-apply SFX vibrato
	ld a, [hl]
	and a, a
	jr z, .ch2
	dec [hl]
	call SfxVibrato
	ld hl, rNR11
	call c, SfxWriteTone
.ch2:
	ld hl, hSfxOwn+1
	ld a, [hl]
	and a, a
	jr z, .ch3
	dec [hl]
	call SfxVibrato
	ld hl, rNR21
	call c, SfxWriteTone
.ch3:
	ld hl, hSfxOwn+2
	ld a, [hl]
	and a, a
	jr z, .ch4
	dec [hl]
	call SfxVibrato
	ld a, $20                               ; NR32 = 100%
	ldh [rNR32], a
	ld hl, rNR33
	call c, SfxWriteFreq
.ch4:
	ld hl, hSfxOwn+3
	ld a, [hl]
	and a, a
	jr z, .music
	dec [hl]
	call SfxVibrato
	call c, SfxWriteNoise
.music:
	ldh a, [hMusicID]
	and a, a
	jp nz, MusicUpdate
	ret

;; SndHandleRequest: A = hSndRequest (nonzero).
SndHandleRequest:
	ldh a, [hSndRequest]
	bit 7, a
	jr nz, .command
	bit 6, a
	jr nz, .song
	and a, $3F
	ld b, a
	ld hl, SfxPriority
	rst $20                                 ; c = priority of the new SFX
	ld c, a
	ldh a, [hSfxID]
	and a, a
	jr z, .startSfx
	ld hl, SfxPriority
	rst $20                                 ; priority of the SFX playing
	cp a, c
	jr c, .startSfx                         ; new >= current: play it
	jr z, .startSfx
	xor a, a                                ; otherwise drop the request
	ldh [hSndRequest], a
	jr SndUpdate.music
.startSfx:
	ld a, b
	call SfxStart
	jr SndUpdate.music
.song:
	and a, $3F
	ld b, a
	ldh a, [hMusicID]
	cp a, b                                 ; same song already playing: ignore
	jp nz, MusicStart
	xor a, a
	ldh [hSndRequest], a
	ret
.command:
	and a, $7F
	dec a                                   ; $81 = stop SFX, $82 = stop music
	rst $00

;; Commands ($80 | n), n = 1..2
SndCommandTable:
	dw SndCmdStopSfx
	dw SndCmdStopMusic
SndCmdStopSfx:
	xor a, a
	ldh [hSndRequest], a
	jp SfxStop
SndCmdStopMusic:
	xor a, a
	ldh [hSndRequest], a
	jp MusicCmdEnd
SfxTable:
	dw Sfx01                                ; $01
	dw Sfx02                                ; $02
	dw Sfx03                                ; $03
	dw Sfx04                                ; $04
	dw Sfx05                                ; $05
	dw Sfx06                                ; $06
	dw Sfx07                                ; $07
	dw Sfx08                                ; $08
	dw Sfx09                                ; $09
	dw Sfx0A                                ; $0A
	dw Sfx0B                                ; $0B
	dw Sfx0C                                ; $0C
	dw Sfx0D                                ; $0D
	dw Sfx0E                                ; $0E
	dw Sfx0F                                ; $0F
	dw Sfx0F                                ; SFX $10 = SFX $0F
	dw Sfx11                                ; $11
	dw Sfx12                                ; $12
	dw Sfx13                                ; $13
	dw Sfx14                                ; $14
	dw Sfx15                                ; $15
	dw Sfx16                                ; $16
	dw Sfx17                                ; $17
	dw Sfx18                                ; $18
	dw Sfx19                                ; $19
	dw Sfx1A                                ; $1A
	dw Sfx1B                                ; $1B
	dw Sfx1B                                ; SFX $1C = SFX $1B
	dw Sfx1B                                ; SFX $1D = SFX $1B
	dw Sfx1B                                ; SFX $1E = SFX $1B
	dw Sfx1B                                ; SFX $1F = SFX $1B
	dw Sfx20                                ; $20
	dw Sfx21                                ; $21

;; SfxStart: A = SFX id. Ids >= $22 stop the SFX instead.
SfxStart:
	and a, $3F
	cp a, $22
	jr nc, SndCmdStopSfx
	ldh [hSfxID], a
	dec a
	ld hl, SfxTable
	rst $28
	ld a, [de]                              ; first byte = channel mask
	ldh [hSfxMask], a
	ldh [hSfxChanLeft], a
	inc de
	ld a, e
	ldh [hSfxPtr], a
	ld a, d
	ldh [hSfxPtr+1], a
	xor a, a
	ldh [hSndRequest], a
	ld hl, hSfxTimer
	ld b, $10
.clear:
	ld [hli], a
	dec b
	jr nz, .clear
	jr SfxUpdate

;; SfxVibrato: returns carry and BC = period when SFX vibrato is on.
;; The period alternates +1/-1 around the base every 3 frames.
SfxVibrato:
	ld hl, hSfxVib
	ld a, [hli]
	and a, a
	ret z
	ldh a, [hSfxFreq]
	ld e, a
	ldh a, [hSfxFreq+1]
	ld d, a
	ld a, [hl]
	bit 7, a
	jr nz, .down
	inc de
	jr .step
.down:
	dec de
.step:
	inc [hl]
	ld a, [hl]
	and a, $7F
	cp a, $03
	jr c, .done
	ld a, [hl]
	and a, $80
	xor a, $80
	ld [hld], a
	dec [hl]
.done:
	ld b, d
	ld c, e
	scf
	ret

;; SfxUpdate: runs while hSfxID != 0.
SfxUpdate:
	ld hl, hSfxTimer
	ld a, [hl]
	and a, a
	jr z, SfxTimerExpired
	dec [hl]
	jr z, SfxTimerExpired
	ldh a, [hSfxSlide]                      ; no event this frame: apply slide
	and a, a
	ret z
	ld hl, hSfxFreq
	bit 7, a
	jr nz, .slideDown
	ld e, a
	ld a, [hl]
	add a, e
	ld [hli], a
	ret nc
	inc [hl]
	ret
.slideDown:
	cpl
	inc a
	ld e, a
	ld a, [hl]
	sub a, e
	ld [hli], a
	ret nc
	dec [hl]
	ret

;; Timer ran out: stop (after SEND) or read the next events.
SfxTimerExpired:
	ldh a, [hSfxEndFlag]
	and a, a
	jp nz, SfxStop
	xor a, a                                ; the slide only lasts until the next event
	ldh [hSfxSlide], a

;; SfxReadEvent: bytes with bit 7 set are notes, others are commands (low 3 bits).
SfxReadEvent:
	ldh a, [hSfxChanLeft]
	and a, $0F
	jr nz, .read
	ldh a, [hSfxMask]
	ldh [hSfxChanLeft], a
.read:
	call SfxReadByte
	bit 7, a
	jp nz, SfxNoteEvent
	and a, $07
	rst $00

;; SFX commands 0-7 (7 = duplicate of 1)
SfxCmdTable:
	dw SfxCmdWait
	dw SfxCmdSlide
	dw SfxCmdDuty
	dw SfxCmdEnv
	dw SfxCmdLoop
	dw SfxCmdVibrato
	dw SfxCmdEnd
	dw SfxCmdSlide

;; SfxNoteEvent: A = hi byte (bit 7 set). hi >= $88 replays the previous period
;; (the low byte is still consumed). The note goes to the lowest channel left in
;; hSfxChanLeft, which locks that channel against the music for 32 frames.
SfxNoteEvent:
	cp a, $88
	jr c, .newFreq
	call SfxReadByte
	ldh a, [hSfxLastFreq]
	ld c, a
	ldh a, [hSfxLastFreq+1]
	ld b, a
	jr .assign
.newFreq:
	ld b, a
	ldh [hSfxLastFreq+1], a
	call SfxReadByte
	ld c, a
	ldh [hSfxLastFreq], a
.assign:
	ld hl, hSfxChanLeft
	bit 0, [hl]
	jr z, SfxWriteFreq.ch2
	res 0, [hl]
	ld a, $20
	ldh [hSfxOwn], a
	ld hl, rNR11
	call SfxWriteTone
	jr SfxReadEvent

;; SfxWriteTone: HL = NRx1. Writes NRx1-NRx4 (NRx2 with bits 2-3 cleared).
SfxWriteTone:
	ldh a, [hSfxDuty]
	ld [hli], a
	ldh a, [hSfxEnv]
	and a, $F3
	ld [hli], a
SfxWriteFreq:
	ld a, c
	ldh [hSfxFreq], a
	ld [hli], a
	ld a, b
	and a, $87
	ldh [hSfxFreq+1], a
	ld [hl], a
	ret
.ch2:
	bit 1, [hl]
	jr z, .ch3
	res 1, [hl]
	ld a, $20
	ldh [hSfxOwn+1], a
	ld hl, rNR21
	call SfxWriteTone
	jp SfxReadEvent
.ch3:
	bit 2, [hl]
	jr z, .ch4
	res 2, [hl]
	ld a, $20
	ldh [hSfxOwn+2], a
	ld a, $20
	ldh [rNR32], a
	ld hl, rNR33
	call SfxWriteFreq
	jp SfxReadEvent
.ch4:
	res 3, [hl]
	ld a, $20
	ldh [hSfxOwn+3], a
	call SfxWriteNoise
	jp SfxReadEvent

;; SfxWriteNoise: NR42 = env (bits 0/2/3 cleared), NR43 = $30 | (period & 7).
SfxWriteNoise:
	ldh a, [hSfxEnv]
	and a, $F2
	ldh [rNR42], a
	ld a, c
	and a, $07
	or a, $30
	ldh [hSfxFreq], a
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret

;; SFX command handlers. The event loop continues after each, except WAIT and END.
SfxCmdWait:
	call SfxReadByte
	ldh [hSfxTimer], a
	ret
SfxCmdSlide:
	call SfxReadByte
	ldh [hSfxSlide], a
	jp SfxReadEvent
SfxCmdDuty:
	call SfxReadByte
	ldh [hSfxDuty], a
	jp SfxReadEvent
SfxCmdEnv:
	call SfxReadByte
	ldh [hSfxEnv], a
	jp SfxReadEvent
SfxCmdLoop:
	ldh a, [hSfxLoop]
	and a, a
	jr z, .first
	call SfxReadByte
	ld b, a
	ldh a, [hSfxLoop]
	cp a, b
	jr nz, .again
	xor a, a
	ldh [hSfxLoop], a
	call SfxReadByte
	call SfxReadByte
	jp SfxReadEvent
.first:
	call SfxReadByte
	and a, a
	jr z, .jump
.again:
	ldh a, [hSfxLoop]
	inc a
	ldh [hSfxLoop], a
.jump:
	call SfxReadByte
	ld b, a
	call SfxReadByte
	ld [hl], b
	inc hl
	ld [hl], a
	jp SfxReadEvent
SfxCmdVibrato:
	call SfxReadByte
	and a, $E0
	swap a
	ldh [hSfxVib], a
	xor a, a
	ldh [hSfxVibPhase], a
	jp SfxReadEvent
SfxCmdEnd:
	ld a, $01
	ldh [hSfxEndFlag], a
	ret

;; SfxStop: silence every channel the SFX used, clear the SFX.
;; The lock timers keep running, so the music stays muted on those
;; channels for up to 32 more frames and then resumes at its next note.
SfxStop:
	ld hl, hSfxMask
	bit 0, [hl]
	jr z, .ch2
	ld a, $08
	ldh [rNR12], a
	swap a
	ldh [rNR14], a
.ch2:
	bit 1, [hl]
	jr z, .ch4
	ld a, $08
	ldh [rNR22], a
	swap a
	ldh [rNR24], a
.ch4:
	bit 3, [hl]
	jr z, .ch3
	ld a, $08
	ldh [rNR42], a
	swap a
	ldh [rNR44], a
.ch3:
	bit 2, [hl]
	jr z, .done
	xor a, a
	ldh [rNR32], a
.done:
	xor a, a
	ld [hl], a
	ldh [hSfxID], a
	ret

;; SfxReadByte: A = next SFX byte, advance hSfxPtr (HL = hSfxPtr on return).
SfxReadByte:
	ld hl, hSfxPtr
	xor a, a
	rst $28
	ld a, [de]
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	ret

;; Song header pointers, songs $01-$0B
SongTable:
	dw Song01
	dw Song02                               ; $02
	dw Song03                               ; $03
	dw Song04                               ; $04
	dw Song05                               ; $05
	dw Song06                               ; $06
	dw Song07                               ; $07
	dw Song08                               ; $08
	dw Song09                               ; $09
	dw Song0A                               ; $0A
	dw Song0B                               ; $0B

;; Wave RAM image, loaded at every song start (a triangle)
WaveTriangle:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

;; MusicStart: B = song id | $40. Ids >= $0C stop the music.
;; Clears hMusTrigger..$FFFE, which also wipes the SFX state (see docs, quirk 1).
MusicStart:
	ld a, b
	and a, $3F
	cp a, $0C
	jp nc, SndCmdStopMusic
	ldh [hMusicID], a
	ld c, a
	ld hl, hMusTrigger
	ld b, $53
	xor a, a
.clear:
	ld [hli], a
	dec b
	jr nz, .clear
	ld a, c
	dec a
	ld hl, SongTable
	rst $28
	ld h, d
	ld l, e
	ld a, [hli]
	ldh [hTempoReload], a
	ldh [hTempoCounter], a
	ld a, [hli]
	ldh [hHalfLength], a
	ld de, hMusPtr
	ld b, $0A
.copyHeader:
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copyHeader
	ld hl, WaveTriangle
	ld de, _AUD3WAVERAM
	ld b, $10
.copyWave:
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copyWave
	xor a, a
	ldh [hSndRequest], a
	jp SndInit

;; MusicUpdate: tempo = frame skipping. On 7 of every 8 frames hTempoCounter
;; counts down; when it reaches 0 the whole music tick is skipped.
MusicUpdate:
	ld hl, hTempoCounter
	ld a, [wFrameCounter]
	and a, $07
	jr z, .channels
	dec [hl]
	jr nz, .channels
	ldh a, [hTempoReload]
	ld [hl], a
	ret
.channels:
	ldh a, [hMusPtr+1]
	and a, a
	jr z, .ch2
	xor a, a
	call MusicChannelTick
.ch2:
	ldh a, [hMusPtr+3]
	and a, a
	jr z, .ch3
	ld a, $01
	call MusicChannelTick
.ch3:
	ldh a, [hMusPtr+5]
	and a, a
	jr z, .ch4
	ld a, $02
	call MusicChannelTick
.ch4:
	ldh a, [hMusPtr+7]
	and a, a
	ret z
	ld a, $03

;; MusicChannelTick: A = channel. Count the note down; while it lasts,
;; apply vibrato (+-1 every 3 frames). When it ends, read events.
MusicChannelTick:
	ldh [hCurChan], a
	ld hl, hNoteTimer
	add a, l
	ld l, a
	ld a, [hl]
	and a, a
	jr z, MusicReadEvent
	dec [hl]
	jr z, MusicReadEvent
	ld hl, hMusFreq
	ldh a, [hCurChan]
	rst $28
	ld hl, hMusVib
	ldh a, [hCurChan]
	sla a
	add a, l
	ld l, a
	ld a, [hli]
	and a, a
	ret z
	ld a, [hl]
	bit 7, a
	jr nz, .down
	inc de
	jr .step
.down:
	dec de
.step:
	inc [hl]
	ld a, [hl]
	and a, $7F
	cp a, $03
	jr c, .write
	ld a, [hl]
	and a, $80
	xor a, $80
	ld [hld], a
	dec [hl]
.write:
	ld b, d
	ld c, e
	ld hl, ChannelNRx1
	ldh a, [hCurChan]
	rst $28
	inc de
	inc de
	ld a, $80
	ldh [hMusTrigger], a
	ld hl, hSfxOwn
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld a, [hl]
	and a, a
	ret nz
	jp MusicWriteFreq

;; MusicReadEvent: $00-$09 commands, $0A-$0F (unused) skip one byte,
;; $10-$20 end the tick without a note, $21-$2F TIE, $30 TRIPLET, $31+ notes.
MusicReadEvent:
	ld a, $C0
	ldh [hMusTrigger], a
	call MusicReadByte
	cp a, $10
	jp nc, MusicNoteByte
	cp a, $0A
	jr nc, MusicCmdIgnore
	rst $00

;; Music commands $00-$09
MusicCmdTable:
	dw MusicCmdIgnore
	dw MusicCmdIgnore
	dw MusicCmdDuty
	dw MusicCmdVolume
	dw MusicCmdLoop
	dw MusicCmdBase
	dw MusicCmdDotted
	dw MusicCmdEnvelope
	dw MusicCmdVibrato
	dw MusicCmdEnd

;; Commands $00, $01 and $0A-$0F: argument ignored (tempo etc. on the NES)
MusicCmdIgnore:
	call MusicReadByte
	jp MusicReadEvent
MusicCmdDuty:
	call MusicReadByte
	ld b, a
	ld hl, hMusDuty
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld [hl], b
	jp MusicReadEvent
MusicCmdVolume:
	call MusicReadByte
	ld b, a
	ld hl, hMusVolume
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld [hl], b
	jp MusicReadEvent

;; LOOP count, addr: count 0 = jump forever, else jump count times.
MusicCmdLoop:
	ld hl, hLoopCount
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld a, [hl]
	and a, a
	jr z, .first
	push hl
	call MusicReadByte
	pop hl
	cp a, [hl]
	jr nz, .again
	ld [hl], $00
	call MusicReadByte
	call MusicReadByte
	jp MusicReadEvent
.first:
	push hl
	call MusicReadByte
	pop hl
	and a, a
	jr z, .jump
.again:
	inc [hl]
.jump:
	call MusicReadByte
	ld b, a
	call MusicReadByte
	ld [hl], b
	inc hl
	ld [hl], a
	jp MusicReadEvent

;; BASE n: note pitch p plays FreqTable[n + p]
MusicCmdBase:
	call MusicReadByte
	sla a
	ld de, FreqTable
	add a, e
	ld e, a
	jr nc, .l44AA
	inc d
.l44AA:
	ld hl, hNoteBase
	ldh a, [hCurChan]
	sla a
	add a, l
	ld l, a
	ld [hl], e
	inc hl
	ld [hl], d
	jp MusicReadEvent

;; DOTTED: the next note (read here) lasts 1.5x
MusicCmdDotted:
	call MusicReadByte
	call MusicSetLength
	ld a, [hl]
	srl a
	add a, [hl]
	ld [hl], a
	jr MusicPlayNote
MusicCmdEnvelope:
	call MusicReadByte
	ld b, a
	ld hl, hMusEnvelope
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld [hl], b
	jp MusicReadEvent

;; VIBRATO n: enable = hVibTable[n] & $E0
MusicCmdVibrato:
	call MusicReadByte
	ld hl, hMusVib
	ldh a, [hCurChan]
	sla a
	add a, l
	ld l, a
	ld d, h
	ld e, l
	ldh a, [hVibTable+1]
	ld h, a
	ldh a, [hVibTable]
	ld l, a
	ldh a, [hCurByte]
	rst $20
	and a, $E0
	ld [de], a
	inc de
	xor a, a
	ld [de], a
	jp MusicReadEvent

;; MUS_END: stop the whole song
MusicCmdEnd:
	xor a, a
	ldh [hMusicID], a
	jp SndInit

;; TIE: bytes $21-$2F merge the next (b - $1F) notes into one
MusicTie:
	sub a, $1F
	ldh [hTieCount], a
	jp MusicReadEvent

;; Note byte: bits 7-5 = length index, bits 4-0 = pitch (0 = rest)
MusicNoteByte:
	ld hl, hTripletFlag
	ldh a, [hCurByte]
	cp a, $21
	ret c
	cp a, $30
	jr c, MusicTie
	jr nz, MusicNote
	inc [hl]
	jp MusicReadEvent
MusicNote:
	call MusicSetLength
	ld hl, hTieCount
	ld a, [hl]
	and a, a
	jr z, MusicPlayNote
	dec [hl]
	jp nz, MusicReadEvent

;; MusicPlayNote: skipped for a rest, or while an SFX owns the channel.
;; NRx1 = duty | (timer / 2), so the hardware length counter cuts the note.
MusicPlayNote:
	ldh a, [hCurByte]
	and a, $1F
	ret z
	ld hl, hSfxOwn
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld a, [hl]
	and a, a
	ret nz
	ld hl, ChannelNRx1
	ldh a, [hCurChan]
	rst $28
	ld hl, hMusDuty
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld b, [hl]
	ld hl, hNoteTimer
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld a, [hl]
	srl a
	or a, b
	ld [de], a
	inc de
	ld hl, hMusVolume
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld b, [hl]
	ld hl, hMusEnvelope
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ld a, [hl]
	or a, b
	ld [de], a
	inc de
	call MusicGetFreq

;; MusicWriteFreq: BC = period, DE = NRx3. Writes NRx3 and NRx4 (| hMusTrigger).
MusicWriteFreq:
	ld hl, hMusFreq
	ldh a, [hCurChan]
	sla a
	add a, l
	ld l, a
	ld a, c
	ld [hli], a
	ld [de], a
	inc de
	ld [hl], b
	ldh a, [hMusTrigger]
	or a, b
	and a, $C7
	ld [de], a
	ret

;; MusicReadByte: A = hCurByte = next byte of the current channel
MusicReadByte:
	ld hl, hMusPtr
	ldh a, [hCurChan]
	rst $28
	ld a, [de]
	ldh [hCurByte], a
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	ret

;; MusicSetLength: note timer = length[hCurByte >> 5] (halved if hHalfLength),
;; added to the old timer during a TIE.
MusicSetLength:
	ld hl, NoteLengths
	ldh a, [hTripletFlag]
	and a, a
	jr z, .gotTable
	ld hl, TripletLengths
.gotTable:
	ldh a, [hCurByte]
	and a, $E0
	swap a
	srl a
	rst $20
	ld b, a
	ldh a, [hHalfLength]
	and a, a
	jr z, .store
	srl b
.store:
	ld hl, hNoteTimer
	ldh a, [hCurChan]
	add a, l
	ld l, a
	ldh a, [hTieCount]
	and a, a
	jr z, .set
	ld a, [hl]
	add a, b
	ld b, a
.set:
	ld [hl], b
	xor a, a
	ldh [hTripletFlag], a
	ret

;; MusicGetFreq: BC = period for hCurByte. CH4: NR43 = $30 | (pitch & 7).
MusicGetFreq:
	push de
	ld hl, hNoteBase
	ldh a, [hCurChan]
	cp a, $03
	jr z, .noise
	add a, a
	add a, l
	ld l, a
	ld a, [hli]
	ld c, a
	ld b, [hl]
	ld h, b
	ld l, c
	ldh a, [hCurByte]
	and a, $1F
	rst $28
	ld b, d
	ld c, e
	pop de
	ret
.noise:
	ldh a, [hCurByte]
	and a, $07
	or a, $30
	ld c, a
	ld b, $00
	pop de
	ret

;; NRx1 address per channel
ChannelNRx1:
	dw rNR11
	dw rNR21
	dw rNR31
	dw rNR41

;; Note lengths in ticks, index = bits 7-5 of the note byte
NoteLengths:
	db $00, $01, $03, $06, $0C, $18, $30, $60

;; Lengths after TRIPLET
TripletLengths:
	db $00, $01, $02, $04, $08, $10, $20, $40

;; Periods. Entries 0-11 are 0; entry 12 = C2 ... entry 83 = B7.
FreqTable:
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
	dw $000
FreqTable_C2:
	dw $02B                ; C_2
	dw $09C                ; C#2
	dw $106                ; D_2
	dw $16A                ; D#2
	dw $1C9                ; E_2
	dw $222                ; F_2
	dw $277                ; F#2
	dw $2C9                ; G_2
	dw $311                ; G#2
	dw $358                ; A_2
	dw $39B                ; A#2
	dw $3DA                ; B_2
	dw $415                ; C_3
	dw $44E                ; C#3
	dw $483                ; D_3
	dw $4B5                ; D#3
	dw $4E4                ; E_3
	dw $511                ; F_3
	dw $53B                ; F#3
	dw $563                ; G_3
	dw $588                ; G#3
	dw $5AC                ; A_3
	dw $5CD                ; A#3
	dw $5ED                ; B_3
	dw $60B                ; C_4
	dw $627                ; C#4
	dw $641                ; D_4
	dw $65A                ; D#4
	dw $672                ; E_4
	dw $688                ; F_4
	dw $69D                ; F#4
	dw $6B1                ; G_4
	dw $6C4                ; G#4
	dw $6D6                ; A_4
	dw $6E6                ; A#4
	dw $6F6                ; B_4
	dw $705                ; C_5
	dw $713                ; C#5
	dw $720                ; D_5
	dw $72D                ; D#5
	dw $739                ; E_5
	dw $744                ; F_5
	dw $74E                ; F#5
	dw $758                ; G_5
	dw $762                ; G#5
	dw $76B                ; A_5
	dw $773                ; A#5
	dw $77B                ; B_5
	dw $782                ; C_6
	dw $789                ; C#6
	dw $790                ; D_6
	dw $796                ; D#6
	dw $79C                ; E_6
	dw $7A2                ; F_6
	dw $7A7                ; F#6
	dw $7AC                ; G_6
	dw $7B1                ; G#6
	dw $7B5                ; A_6
	dw $7B9                ; A#6
	dw $7BD                ; B_6
	dw $7C1                ; C_7
	dw $7C4                ; C#7
	dw $7C8                ; D_7
	dw $7CB                ; D#7
	dw $7CE                ; E_7
	dw $7D1                ; F_7
	dw $7D3                ; F#7
	dw $7D6                ; G_7
	dw $7D8                ; G#7
	dw $7DA                ; A_7
	dw $7DC                ; A#7
	dw $7DE                ; B_7

;; Song $01 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song01:
	db $04, 0
	dw Song01_Ch1
	dw Song01_Ch2
	dw Song01_Ch3
	dw Song01_Ch4
	dw Song01_Vib
Song01_Ch1:
	ENVELOPE 6
	BASE 35
	VOLUME $A0
.l46AD:
	REST L8
	NOTE L8, 5        ; E_4
	REST L8
	NOTE L8, 5        ; E_4
	REST L8
	NOTE L8, 6        ; F_4
	REST L16
	DOTTED L8, 8      ; G_4
	LOOP 1, .l46AD
	DUTY $80
	ENVELOPE 0
	REST L8
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L8, 17       ; E_5
	NOTE L16, 15      ; D_5
	REST L8
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L16
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	REST L8
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L16, 25      ; C_6
	REST L16
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	NOTE L16, 20      ; G_5
	NOTE L16, 17      ; E_5
	NOTE L16, 15      ; D_5
	REST L8
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L16
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	NOTE L4, 13       ; C_5
	REST L8
	NOTE L8, 13       ; C_5
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	TIE 2
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	NOTE L32, 14      ; C#5
	NOTE L32, 15      ; D_5
	REST L16
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	TIE 2
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L16, 13      ; C_5
	REST L16
	DOTTED L1, 20     ; G_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	NOTE L16, 20      ; G_5
	NOTE L16, 28      ; D#6
	NOTE L16, 27      ; D_6
	NOTE L16, 25      ; C_6
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	DUTY $40
.l471F:
	TRIPLET
	NOTE L8, 25       ; C_6
	TRIPLET
	NOTE L16, 25      ; C_6
	REST L4
	TRIPLET
	NOTE L8, 25       ; C_6
	TRIPLET
	NOTE L16, 25      ; C_6
	REST L4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L4, 25       ; C_6
	BASE 34
	LOOP 1, .l471F
.l4733:
	TRIPLET
	NOTE L8, 24       ; A#5
	TRIPLET
	NOTE L16, 24      ; A#5
	REST L4
	TRIPLET
	NOTE L8, 24       ; A#5
	TRIPLET
	NOTE L16, 24      ; A#5
	REST L4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L4, 24       ; A#5
	BASE 33
	LOOP 1, .l4733
	BASE 35
	DUTY $00
	ENVELOPE 9
	TRIPLET
	NOTE L8, 13       ; C_5
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	TRIPLET
	NOTE L8, 13       ; C_5
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	NOTE L8, 13       ; C_5
	TRIPLET
	NOTE L32, 14      ; C#5
	TRIPLET
	NOTE L32, 15      ; D_5
	NOTE L8, 13       ; C_5
	TRIPLET
	REST L8
	TIE 2
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L16, 16      ; D#5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L4, 14       ; C#5
	REST L8
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 8       ; G_4
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	NOTE L8, 13       ; C_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 9       ; G#4
	TRIPLET
	NOTE L8, 8        ; G_4
	TRIPLET
	NOTE L16, 7       ; F#4
	TRIPLET
	NOTE L8, 8        ; G_4
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	TIE 2
	NOTE L8, 5        ; E_4
	TRIPLET
	NOTE L16, 5       ; E_4
	NOTE L4, 4        ; D#4
	NOTE L4, 3        ; D_4
	NOTE L16, 1       ; C_4
	REST L16
	REST L8
	REST L4
	GOTO Song01_Ch1
Song01_Ch2:
	BASE 23
	ENVELOPE 6
	VOLUME $90
	REST L8
	NOTE L8, 8        ; G_3
	REST L8
	NOTE L8, 8        ; G_3
	REST L8
	NOTE L8, 10       ; A_3
	REST L16
	DOTTED L8, 12     ; B_3
	LOOP 1, Song01_Ch2
	BASE 35
	DUTY $80
	ENVELOPE 0
	VOLUME $60
	DOTTED_REST L16
	REST L8
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L8, 17       ; E_5
	NOTE L16, 15      ; D_5
	REST L8
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L16
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	REST L8
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	REST L16
	NOTE L16, 20      ; G_5
	NOTE L16, 25      ; C_6
	REST L16
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	NOTE L16, 20      ; G_5
	NOTE L16, 17      ; E_5
	NOTE L16, 15      ; D_5
	REST L8
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L16
	TIE 2
	NOTE L16, 15      ; D_5
	NOTE L4, 15       ; D_5
	NOTE L4, 13       ; C_5
	REST L8
	NOTE L8, 13       ; C_5
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	TIE 2
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	NOTE L32, 14      ; C#5
	NOTE L32, 15      ; D_5
	REST L16
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L32, 16      ; D#5
	NOTE L32, 17      ; E_5
	TIE 2
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L32, 13      ; C_5
	DUTY $C0
	ENVELOPE 0
	VOLUME $90
	NOTE L8, 12       ; B_4
	REST L16
	TIE 2
	NOTE L16, 12      ; B_4
	NOTE L4, 12       ; B_4
	NOTE L8, 13       ; C_5
	REST L16
	TIE 2
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	NOTE L8, 14       ; C#5
	REST L16
	TIE 2
	NOTE L16, 14      ; C#5
	NOTE L4, 14       ; C#5
	NOTE L16, 15      ; D_5
	DUTY $80
	ENVELOPE 0
	VOLUME $60
	DOTTED_REST L16
	NOTE L16, 20      ; G_5
	NOTE L32, 21      ; G#5
	NOTE L32, 22      ; A_5
	NOTE L16, 20      ; G_5
	NOTE L16, 28      ; D#6
	NOTE L16, 27      ; D_6
	NOTE L32, 25      ; C_6
	DUTY $40
	VOLUME $90
.l4833:
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L16, 17      ; E_5
	REST L4
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L16, 17      ; E_5
	REST L4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L4, 17       ; E_5
	LOOP 2, .l4833
	TRIPLET
	NOTE L8, 18       ; F_5
	TRIPLET
	NOTE L16, 18      ; F_5
	REST L4
	TRIPLET
	NOTE L8, 18       ; F_5
	TRIPLET
	NOTE L16, 18      ; F_5
	REST L4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L4, 18       ; F_5
	DUTY $00
	ENVELOPE 9
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 10      ; A_4
	NOTE L4, 10       ; A_4
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	REST L8
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L4, 8        ; G_4
	NOTE L16, 7       ; F#4
	REST L16
	NOTE L16, 6       ; F_4
	REST L16
	NOTE L4, 5        ; E_4
	REST L8
	VOLUME $60
	DOTTED_REST L16
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 8       ; G_4
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	NOTE L8, 13       ; C_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 9       ; G#4
	TRIPLET
	NOTE L8, 8        ; G_4
	TRIPLET
	NOTE L16, 7       ; F#4
	TRIPLET
	NOTE L8, 8        ; G_4
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	TIE 2
	NOTE L32, 5       ; E_4
	TRIPLET
	NOTE L16, 5       ; E_4
	BASE 23
	VOLUME $90
	NOTE L4, 7        ; F#3
	NOTE L4, 6        ; F_3
	NOTE L16, 5       ; E_3
	REST L16
	REST L8
	REST L4
	GOTO Song01_Ch2
Song01_Ch3:
	VOLUME $20
	BASE 35
.l48B0:
	NOTE L4, 13       ; C_5
	NOTE L4, 10       ; A_4
	DOTTED L8, 3      ; D_4
	TIE 2
	NOTE L16, 8       ; G_4
	NOTE L4, 8        ; G_4
	LOOP 1, .l48B0
	NOTE L4, 13       ; C_5
	DOTTED L8, 8      ; G_4
	NOTE L16, 1       ; C_4
	REST L16
	NOTE L16, 1       ; C_4
	REST L16
	NOTE L16, 1       ; C_4
	NOTE L16, 5       ; E_4
	DOTTED L8, 8      ; G_4
	NOTE L4, 3        ; D_4
	DOTTED L8, 10     ; A_4
	NOTE L16, 8       ; G_4
	REST L16
	NOTE L16, 8       ; G_4
	REST L16
	NOTE L16, 8       ; G_4
	NOTE L16, 12      ; B_4
	DOTTED L8, 15     ; D_5
	NOTE L4, 13       ; C_5
	DOTTED L8, 8      ; G_4
	NOTE L16, 1       ; C_4
	REST L16
	NOTE L16, 1       ; C_4
	REST L16
	NOTE L16, 1       ; C_4
	NOTE L16, 5       ; E_4
	DOTTED L8, 8      ; G_4
	NOTE L4, 3        ; D_4
	DOTTED L8, 10     ; A_4
	NOTE L16, 5       ; E_4
	REST L16
	NOTE L16, 5       ; E_4
	REST L16
	NOTE L16, 5       ; E_4
	NOTE L8, 7        ; F#4
	NOTE L8, 9        ; G#4
	NOTE L4, 10       ; A_4
	NOTE L16, 13      ; C_5
	NOTE L8, 17       ; E_5
	NOTE L16, 9       ; G#4
	REST L16
	NOTE L16, 9       ; G#4
	REST L16
	NOTE L16, 9       ; G#4
	NOTE L16, 12      ; B_4
	DOTTED L8, 17     ; E_5
	NOTE L4, 8        ; G_4
	NOTE L16, 13      ; C_5
	NOTE L8, 17       ; E_5
	NOTE L16, 7       ; F#4
	REST L16
	NOTE L16, 7       ; F#4
	REST L16
	NOTE L16, 7       ; F#4
	NOTE L16, 13      ; C_5
	DOTTED L8, 17     ; E_5
	NOTE L8, 8        ; G_4
	REST L16
	TIE 2
	NOTE L16, 8       ; G_4
	NOTE L4, 8        ; G_4
	NOTE L8, 10       ; A_4
	REST L16
	TIE 2
	NOTE L16, 10      ; A_4
	NOTE L4, 10       ; A_4
	NOTE L8, 11       ; A#4
	REST L16
	TIE 2
	NOTE L16, 11      ; A#4
	NOTE L4, 11       ; A#4
	BASE 23
	NOTE L16, 24      ; B_4
	NOTE L16, 12      ; B_3
	NOTE L16, 25      ; C_5
	NOTE L16, 13      ; C_4
	NOTE L16, 26      ; C#5
	NOTE L16, 14      ; C#4
	NOTE L16, 27      ; D_5
	NOTE L16, 15      ; D_4
	BASE 35
	TRIPLET
	REST L8
	NOTE L8, 13       ; C_5
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L8, 20       ; G_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L8, 22       ; A_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L8, 20       ; G_5
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L16, 16      ; D#5
	TRIPLET
	NOTE L16, 15      ; D_5
	TRIPLET
	NOTE L16, 13      ; C_5
	TIE 2
	NOTE L8, 12       ; B_4
	TRIPLET
	NOTE L8, 12       ; B_4
	TRIPLET
	NOTE L16, 22      ; A_5
	REST L8
	TIE 3
	NOTE L8, 20       ; G_5
	NOTE L4, 20       ; G_5
	TRIPLET
	NOTE L8, 20       ; G_5
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L8, 19       ; F#5
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L8, 22       ; A_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L8, 20       ; G_5
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L8, 25       ; C_6
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	NOTE L8, 20       ; G_5
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	NOTE L16, 16      ; D#5
	TRIPLET
	NOTE L16, 15      ; D_5
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	REST L16
	TIE 2
	TRIPLET
	NOTE L16, 13      ; C_5
	NOTE L4, 13       ; C_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 18      ; F_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	NOTE L8, 13       ; C_5
	TRIPLET
	NOTE L16, 8       ; G_4
	TRIPLET
	NOTE L8, 6        ; F_4
	REST L8
	NOTE L8, 6        ; F_4
	TRIPLET
	NOTE L16, 6       ; F_4
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	NOTE L8, 7        ; F#4
	REST L8
	NOTE L8, 7        ; F#4
	TRIPLET
	NOTE L16, 7       ; F#4
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 25      ; C_6
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 13      ; C_5
	TRIPLET
	NOTE L8, 24       ; B_5
	TRIPLET
	NOTE L16, 12      ; B_4
	TRIPLET
	NOTE L8, 23       ; A#5
	TRIPLET
	NOTE L16, 11      ; A#4
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L8, 21       ; G#5
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L16, 14      ; C#5
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 8       ; G_4
	TRIPLET
	NOTE L8, 6        ; F_4
	TRIPLET
	NOTE L16, 6       ; F_4
	REST L8
	TRIPLET
	NOTE L8, 7        ; F#4
	TRIPLET
	NOTE L16, 7       ; F#4
	REST L8
	TRIPLET
	NOTE L8, 8        ; G_4
	TRIPLET
	NOTE L16, 8       ; G_4
	TRIPLET
	REST L8
	NOTE L8, 10       ; A_4
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	NOTE L8, 11       ; A#4
	TRIPLET
	NOTE L16, 10      ; A_4
	NOTE L4, 9        ; G#4
	NOTE L4, 11       ; A#4
	NOTE L8, 13       ; C_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L32, 21      ; G#5
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	REST L32
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L32, 16      ; D#5
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	REST L32
	TRIPLET
	NOTE L16, 15      ; D_5
	GOTO .l48B0
Song01_Ch4:
	VOLUME $40
.l49EB:
	ENVELOPE 2
	NOTE L16, 3
	NOTE L16, 3
	NOTE L8, 13
	LOOP 5, .l49EB
.l49F4:
	ENVELOPE 3
	DOTTED L16, 8
	DOTTED L16, 8
	NOTE L16, 8
	LOOP 1, .l49F4
.l49FF:
	ENVELOPE 2
	NOTE L16, 3
	NOTE L16, 3
	NOTE L8, 13
	LOOP 14, .l49FF
	ENVELOPE 3
	NOTE L16, 8
	NOTE L8, 8
	NOTE L16, 8
.l4A0D:
	ENVELOPE 3
	DOTTED L8, 13
	NOTE L16, 13
	DOTTED L8, 8
	NOTE L8, 13
	NOTE L16, 13
	NOTE L8, 13
	DOTTED L8, 8
	NOTE L16, 8
	LOOP 1, .l4A0D
.l4A1E:
	NOTE L4, 13
	REST L16
	NOTE L16, 10
	NOTE L16, 9
	NOTE L16, 8
	LOOP 2, .l4A1E
	NOTE L16, 13
	NOTE L16, 13
	REST L8
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 6
	NOTE L16, 6
.l4A2E:
	ENVELOPE 2
	TRIPLET
	NOTE L8, 13
	TRIPLET
	NOTE L16, 3
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 13
	ENVELOPE 5
	TRIPLET
	NOTE L8, 8
	ENVELOPE 2
	TRIPLET
	NOTE L16, 3
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 13
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 13
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 13
	ENVELOPE 5
	TRIPLET
	NOTE L8, 8
	ENVELOPE 2
	TRIPLET
	NOTE L16, 3
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 3
	LOOP 2, .l4A2E
	ENVELOPE 2
	TRIPLET
	NOTE L8, 13
	TRIPLET
	NOTE L16, 3
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 13
	ENVELOPE 5
	TRIPLET
	NOTE L8, 8
	ENVELOPE 2
	TRIPLET
	NOTE L16, 3
.l4A6E:
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 13
	LOOP 2, .l4A6E
	ENVELOPE 5
	TRIPLET
	NOTE L8, 8
	TRIPLET
	NOTE L16, 8
	TRIPLET
	NOTE L16, 6
	TRIPLET
	NOTE L16, 6
	TRIPLET
	NOTE L16, 6
.l4A82:
	ENVELOPE 4
	NOTE L8, 13
	TRIPLET
	REST L8
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 5
	NOTE L8, 8
	TRIPLET
	NOTE L16, 6
	LOOP 1, .l4A82
	ENVELOPE 4
	NOTE L4, 13
	REST L4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 8
	NOTE L8, 8
	TRIPLET
	NOTE L8, 6
	NOTE L8, 6
	TRIPLET
	NOTE L16, 4
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	TRIPLET
	NOTE L8, 8
	NOTE L8, 13
	TRIPLET
	NOTE L16, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L4, 13
	TRIPLET
	NOTE L8, 8
	TRIPLET
	NOTE L16, 8
	TRIPLET
	NOTE L8, 6
	TRIPLET
	NOTE L16, 6
	GOTO .l49EB
Song01_Vib:
	db $00

;; Song $02 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song02:
	db $20, 0
	dw Song02_Ch1
	dw Song02_Ch2
	dw Song02_Ch3
	dw Song02_Ch4
	dw Song02_Vib
Song02_Ch1:
	VOLUME $C0
	BASE 32
	DUTY $C0
	ENVELOPE 6
	NOTE L2, 25       ; A_5
	NOTE L2, 28       ; C_6
	NOTE L2, 27       ; B_5
	NOTE L2, 21       ; F_5
	NOTE L1, 20       ; E_5
.l4AD7:
	DUTY $C0
	ENVELOPE 6
	NOTE L2, 25       ; A_5
	NOTE L2, 28       ; C_6
	NOTE L8, 27       ; B_5
	NOTE L4, 21       ; F_5
	NOTE L4, 20       ; E_5
	DUTY $00
	ENVELOPE 0
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	NOTE L2, 7        ; D#4
	NOTE L2, 4        ; C_4
	NOTE L8, 1        ; A_3
	REST L8
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	NOTE L8, 23       ; G_5
	NOTE L8, 22       ; F#5
	NOTE L8, 18       ; D_5
	BASE 44
	ENVELOPE 6
	DUTY $C0
	NOTE L2, 18       ; D_6
	NOTE L2, 21       ; F_6
	NOTE L8, 20       ; E_6
	NOTE L4, 14       ; A#5
	NOTE L4, 13       ; A_5
	BASE 32
	DUTY $00
	ENVELOPE 0
	NOTE L8, 13       ; A_4
	NOTE L8, 9        ; F_4
	NOTE L8, 6        ; D_4
	NOTE L4, 9        ; F_4
	NOTE L8, 6        ; D_4
	REST L8
	NOTE L8, 9        ; F_4
	NOTE L8, 13       ; A_4
	REST L8
	ENVELOPE 0
	NOTE L16, 18      ; D_5
	NOTE L16, 18      ; D_5
	NOTE L16, 18      ; D_5
	REST L16
	NOTE L16, 18      ; D_5
	REST L16
	REST L8
	NOTE L8, 18       ; D_5
	REST L8
	NOTE L8, 18       ; D_5
	NOTE L4, 25       ; A_5
	DUTY $C0
	ENVELOPE 6
	NOTE L2, 25       ; A_5
	NOTE L2, 28       ; C_6
	NOTE L8, 27       ; B_5
	NOTE L4, 21       ; F_5
	NOTE L4, 20       ; E_5
	DUTY $00
	ENVELOPE 0
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	NOTE L2, 7        ; D#4
	NOTE L2, 4        ; C_4
	NOTE L8, 1        ; A_3
	REST L8
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	BASE 44
	NOTE L8, 11       ; G_5
	NOTE L8, 10       ; F#5
	NOTE L8, 6        ; D_5
	ENVELOPE 4
	DUTY $C0
	NOTE L8, 18       ; D_6
	NOTE L8, 21       ; F_6
	NOTE L4, 18       ; D_6
	BASE 32
	ENVELOPE 0
	DUTY $00
	REST L8
	NOTE L16, 25      ; A_5
	NOTE L16, 25      ; A_5
	REST L8
	NOTE L4, 25       ; A_5
	ENVELOPE 4
	DUTY $C0
	NOTE L8, 30       ; D_6
	NOTE L8, 28       ; C_6
	NOTE L4, 30       ; D_6
	ENVELOPE 0
	DUTY $00
	NOTE L8, 21       ; F_5
	NOTE L8, 20       ; E_5
	NOTE L4, 18       ; D_5
	NOTE L8, 16       ; C_5
	NOTE L8, 15       ; B_4
	NOTE L4, 13       ; A_4
	NOTE L8, 12       ; G#4
	NOTE L8, 13       ; A_4
	NOTE L8, 15       ; B_4
	ENVELOPE 5
	DUTY $C0
	NOTE L4, 18       ; D_5
	NOTE L8, 21       ; F_5
	NOTE L8, 23       ; G_5
	REST L8
	NOTE L8, 25       ; A_5
	NOTE L4, 28       ; C_6
	DUTY $00
	ENVELOPE 2
	TIE 2
	NOTE L4, 8        ; E_4
	VIBRATO 1
	NOTE L4, 8        ; E_4
	VIBRATO 0
	NOTE L8, 9        ; F_4
	NOTE L8, 8        ; E_4
	NOTE L8, 9        ; F_4
	TIE 2
	NOTE L8, 11       ; G_4
	VIBRATO 1
	NOTE L2, 11       ; G_4
	VIBRATO 0
	NOTE L8, 14       ; A#4
	NOTE L8, 11       ; G_4
	NOTE L8, 14       ; A#4
	TIE 2
	NOTE L8, 16       ; C_5
	VIBRATO 1
	NOTE L2, 16       ; C_5
	VIBRATO 0
	NOTE L8, 14       ; A#4
	NOTE L8, 11       ; G_4
	NOTE L8, 14       ; A#4
	NOTE L8, 16       ; C_5
	NOTE L8, 19       ; D#5
	NOTE L8, 16       ; C_5
	NOTE L8, 19       ; D#5
	REST L8
	NOTE L8, 21       ; F_5
	NOTE L4, 23       ; G_5
	BASE 44
	TIE 2
	NOTE L8, 16       ; C_6
	VIBRATO 2
	NOTE L2, 16       ; C_6
	VIBRATO 0
	NOTE L8, 14       ; A#5
	NOTE L8, 16       ; C_6
	NOTE L8, 19       ; D#6
	TIE 2
	NOTE L8, 11       ; G_5
	NOTE L8, 11       ; G_5
	NOTE L8, 16       ; C_6
	NOTE L8, 19       ; D#6
	NOTE L4, 14       ; A#5
	NOTE L8, 10       ; F#5
	NOTE L8, 9        ; F_5
	NOTE L8, 7        ; D#5
	NOTE L4, 9        ; F_5
	NOTE L8, 4        ; C_5
	NOTE L8, 7        ; D#5
	NOTE L16, 8       ; E_5
	NOTE L16, 9       ; F_5
	NOTE L16, 12      ; G#5
	REST L16
	NOTE L16, 15      ; B_5
	NOTE L16, 14      ; A#5
	NOTE L16, 11      ; G_5
	NOTE L16, 7       ; D#5
	DUTY $80
	ENVELOPE 1
	TRIPLET
	NOTE L4, 20       ; E_6
	TRIPLET
	NOTE L4, 15       ; B_5
	TRIPLET
	NOTE L4, 12       ; G#5
	TRIPLET
	NOTE L4, 8        ; E_5
	TRIPLET
	NOTE L4, 3        ; B_4
	BASE 32
	TRIPLET
	NOTE L4, 12       ; G#4
	GOTO .l4AD7
Song02_Ch2:
	BASE 32
	DUTY $C0
	ENVELOPE 6
	VOLUME $90
	NOTE L2, 20       ; E_5
	NOTE L2, 23       ; G_5
	NOTE L2, 22       ; F#5
	NOTE L2, 16       ; C_5
	NOTE L1, 15       ; B_4
.l4BD0:
	BASE 32
	VOLUME $90
	DUTY $C0
	ENVELOPE 6
	NOTE L2, 20       ; E_5
	NOTE L2, 23       ; G_5
	NOTE L8, 22       ; F#5
	NOTE L4, 16       ; C_5
	NOTE L4, 15       ; B_4
	DUTY $00
	VOLUME $60
	ENVELOPE 0
	TRIPLET
	REST L8
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	NOTE L2, 7        ; D#4
	NOTE L2, 4        ; C_4
	NOTE L8, 1        ; A_3
	REST L8
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	NOTE L8, 23       ; G_5
	NOTE L8, 22       ; F#5
	TRIPLET
	NOTE L16, 18      ; D_5
	VOLUME $90
	ENVELOPE 6
	DUTY $C0
	NOTE L2, 25       ; A_5
	NOTE L2, 28       ; C_6
	NOTE L8, 27       ; B_5
	NOTE L4, 21       ; F_5
	NOTE L4, 20       ; E_5
	VOLUME $60
	DUTY $00
	ENVELOPE 0
	TRIPLET
	REST L8
	NOTE L8, 13       ; A_4
	NOTE L8, 9        ; F_4
	NOTE L8, 6        ; D_4
	NOTE L4, 9        ; F_4
	NOTE L8, 6        ; D_4
	REST L8
	NOTE L8, 9        ; F_4
	NOTE L8, 13       ; A_4
	TRIPLET
	REST L16
	VOLUME $90
	ENVELOPE 0
	NOTE L16, 13      ; A_4
	NOTE L16, 13      ; A_4
	NOTE L16, 13      ; A_4
	REST L16
	NOTE L16, 13      ; A_4
	REST L16
	REST L8
	NOTE L8, 13       ; A_4
	REST L8
	NOTE L8, 13       ; A_4
	NOTE L4, 18       ; D_5
	DUTY $C0
	ENVELOPE 6
	NOTE L2, 20       ; E_5
	NOTE L2, 23       ; G_5
	NOTE L8, 22       ; F#5
	NOTE L4, 16       ; C_5
	NOTE L4, 15       ; B_4
	DUTY $00
	ENVELOPE 0
	VOLUME $60
	TRIPLET
	REST L8
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	NOTE L2, 7        ; D#4
	NOTE L2, 4        ; C_4
	NOTE L8, 1        ; A_3
	REST L8
	NOTE L8, 1        ; A_3
	NOTE L8, 4        ; C_4
	NOTE L8, 8        ; E_4
	BASE 44
	NOTE L8, 11       ; G_5
	NOTE L8, 10       ; F#5
	TRIPLET
	NOTE L16, 6       ; D_5
	VOLUME $90
	BASE 39
	ENVELOPE 4
	DUTY $C0
	NOTE L8, 18       ; A_5
	NOTE L8, 21       ; C_6
	NOTE L4, 18       ; A_5
	ENVELOPE 0
	DUTY $00
	REST L8
	NOTE L16, 13      ; E_5
	NOTE L16, 13      ; E_5
	REST L8
	NOTE L4, 13       ; E_5
	ENVELOPE 4
	DUTY $C0
	NOTE L8, 18       ; A_5
	NOTE L8, 16       ; G_5
	NOTE L4, 18       ; A_5
	BASE 27
	ENVELOPE 0
	DUTY $00
	NOTE L8, 21       ; C_5
	NOTE L8, 20       ; B_4
	NOTE L4, 18       ; A_4
	NOTE L8, 16       ; G_4
	NOTE L8, 15       ; F#4
	NOTE L4, 13       ; E_4
	NOTE L8, 12       ; D#4
	NOTE L8, 13       ; E_4
	NOTE L8, 15       ; F#4
	ENVELOPE 5
	DUTY $C0
	NOTE L4, 18       ; A_4
	NOTE L8, 21       ; C_5
	NOTE L8, 23       ; D_5
	REST L8
	NOTE L8, 25       ; E_5
	NOTE L4, 28       ; G_5
	VIBRATO 1
	BASE 32
	VOLUME $80
	DUTY $00
	ENVELOPE 2
	TRIPLET
	REST L8
	NOTE L2, 8        ; E_4
	NOTE L8, 9        ; F_4
	NOTE L8, 8        ; E_4
	NOTE L8, 9        ; F_4
	TIE 2
	NOTE L8, 11       ; G_4
	NOTE L2, 11       ; G_4
	NOTE L8, 14       ; A#4
	NOTE L8, 11       ; G_4
	NOTE L8, 14       ; A#4
	TIE 2
	NOTE L8, 16       ; C_5
	NOTE L2, 16       ; C_5
	NOTE L8, 14       ; A#4
	NOTE L8, 11       ; G_4
	NOTE L8, 14       ; A#4
	NOTE L8, 16       ; C_5
	NOTE L8, 19       ; D#5
	NOTE L8, 16       ; C_5
	NOTE L8, 19       ; D#5
	REST L8
	NOTE L8, 21       ; F_5
	NOTE L4, 23       ; G_5
	VIBRATO 2
	BASE 44
	TIE 2
	NOTE L8, 16       ; C_6
	NOTE L2, 16       ; C_6
	NOTE L8, 14       ; A#5
	NOTE L8, 16       ; C_6
	NOTE L8, 19       ; D#6
	TIE 2
	NOTE L8, 11       ; G_5
	NOTE L8, 11       ; G_5
	NOTE L8, 16       ; C_6
	NOTE L8, 19       ; D#6
	NOTE L4, 14       ; A#5
	NOTE L8, 10       ; F#5
	NOTE L8, 9        ; F_5
	NOTE L8, 7        ; D#5
	NOTE L4, 9        ; F_5
	NOTE L8, 4        ; C_5
	NOTE L8, 7        ; D#5
	NOTE L16, 8       ; E_5
	NOTE L16, 9       ; F_5
	NOTE L16, 12      ; G#5
	REST L16
	NOTE L16, 15      ; B_5
	NOTE L16, 14      ; A#5
	TRIPLET
	NOTE L16, 11      ; G_5
	VIBRATO 0
	VOLUME $90
	DUTY $80
	BASE 39
	ENVELOPE 1
	TRIPLET
	NOTE L4, 20       ; B_5
	TRIPLET
	NOTE L4, 15       ; F#5
	TRIPLET
	NOTE L4, 12       ; D#5
	TRIPLET
	NOTE L4, 8        ; B_4
	TRIPLET
	NOTE L4, 3        ; F#4
	BASE 27
	TRIPLET
	NOTE L4, 12       ; D#4
	GOTO .l4BD0
Song02_Ch3:
	VOLUME $20
	BASE 20
	NOTE L2, 25       ; A_4
	NOTE L2, 28       ; C_5
	NOTE L2, 27       ; B_4
	NOTE L2, 21       ; F_4
	VOLUME $20
	BASE 32
	NOTE L2, 20       ; E_5
.l4CDE:
	NOTE L16, 20      ; E_5
	NOTE L16, 18      ; D_5
	NOTE L16, 16      ; C_5
	REST L16
	NOTE L16, 15      ; B_4
	REST L16
	NOTE L8, 13       ; A_4
.l4CE5:
	NOTE L2, 13       ; A_4
	NOTE L8, 8        ; E_4
	DOTTED L4, 11     ; G_4
	NOTE L16, 13      ; A_4
	REST L16
	REST L8
	NOTE L4, 13       ; A_4
	NOTE L8, 8        ; E_4
	DOTTED L4, 11     ; G_4
	NOTE L2, 13       ; A_4
	NOTE L8, 8        ; E_4
	DOTTED L4, 11     ; G_4
	NOTE L8, 13       ; A_4
	REST L8
	NOTE L8, 13       ; A_4
	REST L4
	NOTE L8, 13       ; A_4
	NOTE L8, 15       ; B_4
	NOTE L8, 16       ; C_5
	NOTE L2, 18       ; D_5
	NOTE L8, 13       ; A_4
	DOTTED L4, 16     ; C_5
	NOTE L16, 18      ; D_5
	REST L16
	REST L8
	NOTE L4, 18       ; D_5
	NOTE L8, 13       ; A_4
	DOTTED L4, 16     ; C_5
	NOTE L2, 18       ; D_5
	NOTE L8, 13       ; A_4
	DOTTED L4, 16     ; C_5
	NOTE L8, 18       ; D_5
	NOTE L8, 18       ; D_5
	REST L8
	NOTE L8, 18       ; D_5
	REST L8
	NOTE L8, 13       ; A_4
	NOTE L4, 18       ; D_5
	LOOP 1, .l4CE5
	NOTE L8, 4        ; C_4
	REST L8
	NOTE L8, 4        ; C_4
	REST L8
	NOTE L8, 4        ; C_4
	NOTE L4, 11       ; G_4
	NOTE L4, 7        ; D#4
	REST L8
	NOTE L8, 7        ; D#4
	REST L8
	NOTE L8, 7        ; D#4
	NOTE L4, 14       ; A#4
	NOTE L4, 9        ; F_4
	REST L8
	NOTE L8, 9        ; F_4
	REST L8
	NOTE L8, 9        ; F_4
	NOTE L4, 16       ; C_5
	NOTE L4, 12       ; G#4
	REST L8
	NOTE L8, 12       ; G#4
	REST L8
	NOTE L8, 12       ; G#4
	NOTE L4, 19       ; D#5
	NOTE L4, 4        ; C_4
	REST L8
	NOTE L8, 4        ; C_4
	REST L8
	NOTE L8, 4        ; C_4
	NOTE L4, 11       ; G_4
	NOTE L4, 7        ; D#4
	REST L8
	NOTE L8, 7        ; D#4
	REST L8
	NOTE L8, 7        ; D#4
	NOTE L4, 14       ; A#4
	NOTE L4, 9        ; F_4
	REST L8
	NOTE L8, 9        ; F_4
	REST L8
	NOTE L8, 9        ; F_4
	NOTE L4, 16       ; C_5
	NOTE L4, 8        ; E_4
	REST L8
	NOTE L8, 8        ; E_4
	REST L8
	GOTO .l4CDE
Song02_Ch4:
	ENVELOPE 4
	VOLUME $30
	NOTE L1, 13
	NOTE L1, 13
	ENVELOPE 7
	VOLUME $F0
	NOTE L2, 10
	VOLUME $A0
	ENVELOPE 4
	NOTE L16, 12
	NOTE L16, 12
	NOTE L16, 12
	REST L16
	NOTE L16, 11
	REST L16
	NOTE L16, 11
	REST L16
.l4D5E:
	ENVELOPE 3
	NOTE L8, 13
	REST L8
	NOTE L4, 8
	NOTE L16, 13
	NOTE L16, 13
	NOTE L16, 13
	REST L16
	NOTE L4, 8
	NOTE L8, 13
	REST L8
	NOTE L8, 8
	NOTE L8, 13
	REST L8
	NOTE L8, 13
	NOTE L4, 8
	LOOP 7, .l4D5E
.l4D73:
	ENVELOPE 3
	NOTE L8, 13
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 5
	NOTE L8, 8
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 3
	NOTE L8, 13
	ENVELOPE 5
	NOTE L8, 8
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 3
	NOTE L8, 13
	LOOP 3, .l4D73
.l4D8F:
	ENVELOPE 3
	NOTE L8, 13
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 5
	NOTE L8, 8
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 3
	NOTE L16, 13
	NOTE L16, 13
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 5
	NOTE L8, 8
	ENVELOPE 2
	NOTE L8, 3
	LOOP 2, .l4D8F
	ENVELOPE 3
	NOTE L8, 13
	REST L8
	NOTE L4, 8
	NOTE L16, 7
	NOTE L16, 7
	NOTE L16, 7
	NOTE L16, 7
	NOTE L16, 5
	NOTE L16, 5
	NOTE L16, 5
	NOTE L16, 5
	GOTO .l4D5E
Song02_Vib:
	db $00, $62, $42

;; Song $03 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song03:
	db $0C, 0
	dw Song03_Ch1
	dw Song03_Ch2
	dw Song03_Ch3
	dw Song03_Ch4
	dw Song03_Vib
Song03_Ch1:
	VOLUME $C0
.l4DCE:
	REST L4
.l4DCF:
	VIBRATO 1
	BASE 35
	DUTY $00
	ENVELOPE 2
	REST L8
	TRIPLET
	NOTE L16, 4       ; D#4
	TRIPLET
	NOTE L8, 5        ; E_4
	NOTE L16, 8       ; G_4
	NOTE L16, 10      ; A_4
	NOTE L16, 11      ; A#4
	REST L16
	NOTE L16, 12      ; B_4
	NOTE L16, 11      ; A#4
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L16, 8       ; G_4
	NOTE L16, 10      ; A_4
	NOTE L16, 5       ; E_4
	NOTE L16, 3       ; D_4
	NOTE L16, 10      ; A_4
	REST L16
	REST L8
	NOTE L8, 10       ; A_4
	NOTE L16, 5       ; E_4
	REST L16
	REST L2
	REST L8
	TRIPLET
	NOTE L16, 4       ; D#4
	TRIPLET
	NOTE L8, 5        ; E_4
	NOTE L16, 8       ; G_4
	NOTE L16, 10      ; A_4
	NOTE L16, 11      ; A#4
	REST L16
	NOTE L16, 12      ; B_4
	NOTE L16, 11      ; A#4
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L16, 3       ; D_4
	NOTE L16, 10      ; A_4
	NOTE L16, 8       ; G_4
	NOTE L16, 10      ; A_4
	NOTE L16, 12      ; B_4
	REST L8
	REST L16
	NOTE L16, 12      ; B_4
	REST L16
	REST L8
	NOTE L16, 15      ; D_5
	NOTE L16, 12      ; B_4
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L8, 20       ; G_5
	NOTE L16, 17      ; E_5
	REST L16
	REST L8
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L8, 20       ; G_5
	NOTE L16, 17      ; E_5
	NOTE L16, 15      ; D_5
	NOTE L16, 11      ; A#4
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L16, 8       ; G_4
	REST L16
	NOTE L16, 3       ; D_4
	NOTE L16, 5       ; E_4
	REST L16
	NOTE L16, 5       ; E_4
	NOTE L16, 8       ; G_4
	REST L16
	NOTE L16, 8       ; G_4
	NOTE L16, 10      ; A_4
	REST L16
	TRIPLET
	NOTE L16, 10      ; A_4
	TIE 2
	TRIPLET
	NOTE L8, 11       ; A#4
	NOTE L8, 11       ; A#4
	NOTE L16, 10      ; A_4
	NOTE L16, 8       ; G_4
	REST L16
	NOTE L16, 12      ; B_4
	NOTE L16, 15      ; D_5
	REST L16
	REST L8
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L8, 20       ; G_5
	NOTE L16, 17      ; E_5
	REST L16
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L16, 17      ; E_5
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L16, 17      ; E_5
	NOTE L16, 20      ; G_5
	NOTE L16, 22      ; A_5
	NOTE L16, 24      ; B_5
	REST L16
	REST L8
	NOTE L16, 24      ; B_5
	REST L16
	REST L8
	NOTE L16, 23      ; A#5
	NOTE L16, 22      ; A_5
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	DUTY $80
	ENVELOPE 0
	TRIPLET
	NOTE L16, 16      ; D#5
	TRIPLET
	NOTE L8, 17       ; E_5
	REST L8
	NOTE L16, 17      ; E_5
	REST L8
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 17      ; E_5
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L16, 17      ; E_5
	REST L8
	NOTE L8, 17       ; E_5
	NOTE L16, 17      ; E_5
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L16, 22      ; A_5
	NOTE L16, 23      ; A#5
	REST L16
	TRIPLET
	NOTE L16, 21      ; G#5
	TIE 2
	TRIPLET
	NOTE L8, 22       ; A_5
	NOTE L16, 22      ; A_5
	NOTE L16, 20      ; G_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 17      ; E_5
	NOTE L16, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L8
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L16, 20      ; G_5
	NOTE L16, 17      ; E_5
	DUTY $C0
	NOTE L16, 24      ; B_5
	REST L16
	REST L8
	NOTE L16, 24      ; B_5
	REST L16
	DUTY $80
	NOTE L8, 17       ; E_5
	NOTE L16, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L16
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L16, 20      ; G_5
	NOTE L16, 17      ; E_5
	DUTY $C0
	REST L16
	NOTE L16, 24      ; B_5
	REST L8
	NOTE L16, 24      ; B_5
	NOTE L16, 24      ; B_5
	REST L8
	DUTY $80
	TRIPLET
	NOTE L16, 11      ; A#4
	TIE 2
	TRIPLET
	NOTE L16, 12      ; B_4
.l4EA9:
	TRIPLET
	NOTE L16, 12      ; B_4
	TRIPLET
	NOTE L16, 15      ; D_5
	LOOP 4, .l4EA9
	NOTE L16, 20      ; G_5
	NOTE L16, 17      ; E_5
	NOTE L16, 16      ; D#5
	NOTE L16, 15      ; D_5
	NOTE L16, 11      ; A#4
	NOTE L16, 10      ; A_4
	NOTE L16, 8       ; G_4
	NOTE L16, 5       ; E_4
	TRIPLET
	NOTE L16, 9       ; G#4
	TIE 2
	TRIPLET
	NOTE L8, 10       ; A_4
	NOTE L16, 10      ; A_4
	NOTE L16, 14      ; C#5
	NOTE L16, 17      ; E_5
	NOTE L16, 14      ; C#5
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	TRIPLET
	NOTE L16, 20      ; G_5
	NOTE L8, 20       ; G_5
	TRIPLET
	NOTE L8, 19       ; F#5
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L8, 15       ; D_5
	TRIPLET
	NOTE L8, 14       ; C#5
	TRIPLET
	NOTE L16, 11      ; A#4
	TIE 2
	TRIPLET
	NOTE L16, 12      ; B_4
	NOTE L8, 12       ; B_4
	NOTE L16, 12      ; B_4
	REST L16
	REST L8
	NOTE L16, 12      ; B_4
	REST L16
	REST L8
	NOTE L16, 10      ; A_4
	NOTE L16, 12      ; B_4
	NOTE L16, 15      ; D_5
	NOTE L16, 12      ; B_4
	NOTE L8, 11       ; A#4
	NOTE L16, 10      ; A_4
	NOTE L16, 10      ; A_4
	REST L8
	NOTE L16, 22      ; A_5
	NOTE L16, 22      ; A_5
	REST L16
	REST L8
	NOTE L16, 23      ; A#5
	NOTE L16, 22      ; A_5
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L16, 23      ; A#5
	TRIPLET
	NOTE L8, 22       ; A_5
	NOTE L16, 20      ; G_5
	NOTE L16, 15      ; D_5
	GOTO .l4DCF
Song03_Ch2:
	VIBRATO 1
	TRIPLET
	REST L8
	VOLUME $50
	GOTO Song03_Ch1.l4DCE
Song03_Ch3:
	VOLUME $20
.l4F01:
	BASE 23
	NOTE L8, 12       ; B_3
	NOTE L8, 15       ; D_4
	NOTE L8, 17       ; E_4
	REST L2
	NOTE L8, 17       ; E_4
	NOTE L8, 20       ; G_4
	NOTE L8, 21       ; G#4
	NOTE L8, 22       ; A_4
	REST L8
	REST L2
	NOTE L8, 15       ; D_4
	NOTE L8, 16       ; D#4
	NOTE L8, 17       ; E_4
	REST L2
	NOTE L8, 17       ; E_4
	NOTE L8, 20       ; G_4
	NOTE L8, 22       ; A_4
	NOTE L8, 24       ; B_4
	REST L8
	NOTE L8, 24       ; B_4
	REST L8
	NOTE L16, 24      ; B_4
	NOTE L16, 22      ; A_4
	NOTE L8, 20       ; G_4
	LOOP 1, .l4F01
	NOTE L8, 15       ; D_4
	NOTE L8, 17       ; E_4
	BASE 35
	TIE 2
	NOTE L8, 10       ; A_4
	NOTE L2, 10       ; A_4
	NOTE L16, 14      ; C#5
	NOTE L16, 10      ; A_4
	NOTE L16, 16      ; D#5
	NOTE L16, 17      ; E_5
	REST L16
	TIE 2
	NOTE L16, 10      ; A_4
	NOTE L2, 10       ; A_4
	REST L16
	NOTE L8, 20       ; G_5
	REST L16
	NOTE L16, 19      ; F#5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	REST L8
	NOTE L16, 17      ; E_5
	NOTE L16, 17      ; E_5
	REST L4
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 16      ; D#5
	NOTE L16, 17      ; E_5
	REST L8
	NOTE L4, 5        ; E_4
	NOTE L16, 17      ; E_5
	REST L16
	REST L4
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 16      ; D#5
	NOTE L16, 17      ; E_5
	REST L8
	NOTE L4, 12       ; B_4
	NOTE L16, 24      ; B_5
	REST L8
	NOTE L16, 19      ; F#5
	NOTE L16, 15      ; D_5
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L8, 24       ; B_5
	REST L16
	NOTE L8, 23       ; A#5
	REST L16
	DOTTED L8, 10     ; A_4
	NOTE L16, 22      ; A_5
	REST L8
	NOTE L16, 17      ; E_5
	NOTE L16, 14      ; C#5
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L8, 22       ; A_5
	REST L16
	NOTE L8, 23       ; A#5
	REST L16
	DOTTED L8, 12     ; B_4
	NOTE L16, 24      ; B_5
	REST L8
	NOTE L16, 19      ; F#5
	NOTE L16, 15      ; D_5
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L8, 24       ; B_5
	REST L16
	NOTE L8, 23       ; A#5
	REST L16
	DOTTED L8, 10     ; A_4
	NOTE L16, 22      ; A_5
	REST L8
	NOTE L16, 17      ; E_5
	NOTE L16, 14      ; C#5
	NOTE L16, 10      ; A_4
	REST L16
	NOTE L16, 12      ; B_4
	NOTE L16, 10      ; A_4
	NOTE L16, 8       ; G_4
	GOTO .l4F01
Song03_Ch4:
	VOLUME $40
	REST L4
.l4F7C:
	ENVELOPE 3
	NOTE L8, 13
	NOTE L8, 13
	NOTE L8, 8
	REST L4
	NOTE L8, 13
	NOTE L8, 8
	REST L4
	NOTE L8, 13
	NOTE L8, 8
	REST L4
	NOTE L8, 13
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 8
	REST L16
	NOTE L8, 13
	NOTE L8, 13
	NOTE L8, 8
	REST L4
	NOTE L8, 13
	NOTE L8, 8
	REST L8
	NOTE L8, 8
	REST L8
	NOTE L8, 8
	REST L8
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 6
	NOTE L16, 6
	NOTE L16, 6
	NOTE L16, 6
	LOOP 1, .l4F7C
.l4FA4:
	NOTE L16, 13
	REST L8
	NOTE L16, 13
	DOTTED L8, 8
	NOTE L16, 13
	REST L16
	NOTE L16, 13
	NOTE L16, 13
	REST L16
	DOTTED L8, 8
	REST L16
	LOOP 7, .l4FA4
	GOTO .l4F7C
Song03_Vib:
	db $00, $22

;; Song $04 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song04:
	db $05, 0
	dw Song04_Ch1
	dw Song04_Ch2
	dw Song04_Ch3
	dw Song04_Ch4
	dw Song04_Vib
Song04_Ch1:
	VOLUME $A0
	BASE 32
	REST L8
	TRIPLET
	NOTE L16, 16      ; C_5
	TRIPLET
	NOTE L8, 17       ; C#5
	NOTE L16, 21      ; F_5
	REST L16
	NOTE L16, 24      ; G#5
	REST L16
	NOTE L16, 27      ; B_5
	REST L16
	NOTE L16, 26      ; A#5
	NOTE L16, 24      ; G#5
	REST L8
	NOTE L8, 21       ; F_5
	NOTE L16, 22      ; F#5
	REST L16
.l4FDC:
	DUTY $80
	ENVELOPE 5
	BASE 32
	TRIPLET
	NOTE L16, 13      ; A_4
	TRIPLET
	NOTE L8, 14       ; A#4
	NOTE L8, 13       ; A_4
	REST L8
	NOTE L16, 14      ; A#4
	NOTE L16, 14      ; A#4
	REST L16
	NOTE L4, 10       ; F#4
	REST L16
	TRIPLET
	NOTE L16, 11      ; G_4
	TRIPLET
	NOTE L8, 12       ; G#4
	NOTE L16, 14      ; A#4
	REST L16
	NOTE L16, 15      ; B_4
	NOTE L16, 16      ; C_5
	REST L16
	DOTTED L8, 17     ; C#5
	BASE 44
	DUTY $00
	NOTE L16, 17      ; C#6
	NOTE L16, 19      ; D#6
	REST L16
	NOTE L16, 16      ; C_6
	NOTE L16, 17      ; C#6
	REST L16
	BASE 32
	DUTY $80
	REST L8
	TRIPLET
	NOTE L16, 14      ; A#4
	TRIPLET
	NOTE L8, 15       ; B_4
	NOTE L8, 10       ; F#4
	REST L8
	NOTE L16, 15      ; B_4
	NOTE L16, 15      ; B_4
	REST L16
	NOTE L4, 19       ; D#5
	REST L16
	NOTE L16, 17      ; C#5
	REST L16
	NOTE L16, 19      ; D#5
	REST L16
	TRIPLET
	NOTE L8, 17       ; C#5
	TRIPLET
	NOTE L8, 16       ; C_5
	TRIPLET
	NOTE L8, 15       ; B_4
	NOTE L2, 14       ; A#4
	REST L8
	TRIPLET
	NOTE L16, 18      ; D_5
	TRIPLET
	NOTE L8, 19       ; D#5
	NOTE L8, 15       ; B_4
	REST L16
	NOTE L16, 19      ; D#5
	REST L8
	NOTE L16, 22      ; F#5
	REST L16
	TRIPLET
	NOTE L8, 25       ; A_5
	TRIPLET
	NOTE L8, 24       ; G#5
	TRIPLET
	NOTE L8, 22       ; F#5
	DUTY $00
	NOTE L16, 29      ; C#6
	REST L16
	NOTE L16, 29      ; C#6
	REST L16
	TRIPLET
	NOTE L8, 29       ; C#6
	TRIPLET
	NOTE L8, 28       ; C_6
	TRIPLET
	NOTE L8, 27       ; B_5
	NOTE L4, 26       ; A#5
	REST L4
	DUTY $C0
	NOTE L16, 12      ; G#4
	NOTE L16, 12      ; G#4
	REST L16
	NOTE L16, 14      ; A#4
	REST L16
	NOTE L16, 15      ; B_4
	NOTE L16, 16      ; C_5
	REST L16
	NOTE L16, 17      ; C#5
	REST L16
	NOTE L16, 19      ; D#5
	REST L8
	NOTE L16, 13      ; A_4
	NOTE L16, 12      ; G#4
	REST L16
	NOTE L2, 10       ; F#4
	REST L8
	DUTY $80
	ENVELOPE 5
	BASE 44
	NOTE L8, 29       ; C#7
	NOTE L8, 28       ; C_7
	NOTE L8, 27       ; B_6
	BASE 32
	DUTY $00
	ENVELOPE 2
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L8, 25       ; A_5
	REST L8
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L8, 25       ; A_5
	REST L8
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L8, 25       ; A_5
	NOTE L16, 22      ; F#5
	NOTE L16, 20      ; E_5
	REST L8
	NOTE L8, 22       ; F#5
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	REST L16
	NOTE L16, 22      ; F#5
	NOTE L16, 20      ; E_5
	REST L16
	NOTE L16, 16      ; C_5
	NOTE L16, 15      ; B_4
	NOTE L16, 13      ; A_4
	REST L16
	NOTE L16, 10      ; F#4
	NOTE L16, 8       ; E_4
	NOTE L16, 10      ; F#4
	TRIPLET
	NOTE L16, 22      ; F#5
	TRIPLET
	NOTE L16, 15      ; B_4
	TRIPLET
	NOTE L16, 22      ; F#5
	TRIPLET
	NOTE L16, 15      ; B_4
	TRIPLET
	NOTE L16, 22      ; F#5
	TRIPLET
	NOTE L16, 15      ; B_4
	BASE 44
	NOTE L16, 19      ; D#6
	NOTE L16, 19      ; D#6
	REST L16
	NOTE L16, 19      ; D#6
	NOTE L16, 19      ; D#6
	NOTE L16, 15      ; B_5
	NOTE L16, 19      ; D#6
	REST L16
	NOTE L16, 22      ; F#6
	NOTE L16, 19      ; D#6
	NOTE L16, 15      ; B_5
	NOTE L16, 14      ; A#5
	NOTE L4, 10       ; F#5
	NOTE L8, 13       ; A_5
	NOTE L4, 15       ; B_5
	NOTE L8, 14       ; A#5
	NOTE L8, 20       ; E_6
	TRIPLET
	NOTE L16, 21      ; F_6
	TRIPLET
	NOTE L8, 22       ; F#6
	REST L8
	TRIPLET
	NOTE L16, 21      ; F_6
	TRIPLET
	NOTE L8, 22       ; F#6
	REST L8
	TRIPLET
	NOTE L16, 21      ; F_6
	TRIPLET
	NOTE L8, 22       ; F#6
	REST L8
	NOTE L8, 17       ; C#6
	NOTE L8, 14       ; A#5
	TRIPLET
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L8, 25       ; A_6
	NOTE L16, 25      ; A_6
	REST L16
	NOTE L16, 22      ; F#6
	NOTE L16, 20      ; E_6
	REST L16
	NOTE L16, 16      ; C_6
	NOTE L16, 15      ; B_5
	NOTE L16, 13      ; A_5
	REST L8
	NOTE L16, 17      ; C#6
	NOTE L16, 17      ; C#6
	REST L16
	NOTE L16, 17      ; C#6
	NOTE L16, 15      ; B_5
	NOTE L16, 17      ; C#6
	NOTE L16, 20      ; E_6
	REST L16
	NOTE L16, 17      ; C#6
	NOTE L16, 15      ; B_5
	REST L16
	NOTE L16, 17      ; C#6
	REST L8
	REST L16
	NOTE L16, 5       ; C#5
	NOTE L16, 10      ; F#5
	NOTE L16, 12      ; G#5
	REST L16
	NOTE L16, 17      ; C#6
	NOTE L16, 22      ; F#6
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 29       ; C#7
	TRIPLET
	NOTE L8, 29       ; C#7
	TRIPLET
	NOTE L8, 29       ; C#7
	NOTE L16, 29      ; C#7
	DOTTED L8, 20     ; E_6
	REST L8
	GOTO .l4FDC
Song04_Ch2:
	VOLUME $90
	BASE 32
	REST L8
	TRIPLET
	NOTE L16, 11      ; G_4
	TRIPLET
	NOTE L8, 12       ; G#4
	NOTE L16, 17      ; C#5
	REST L16
	NOTE L16, 21      ; F_5
	REST L16
	NOTE L16, 24      ; G#5
	REST L16
	NOTE L16, 22      ; F#5
	NOTE L16, 21      ; F_5
	REST L8
	NOTE L8, 17       ; C#5
	NOTE L16, 14      ; A#4
	REST L16
.l510F:
	DUTY $80
	ENVELOPE 5
	BASE 32
	VOLUME $90
	TRIPLET
	NOTE L16, 9       ; F_4
	TRIPLET
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	REST L8
	NOTE L16, 10      ; F#4
	NOTE L16, 10      ; F#4
	REST L16
	NOTE L4, 10       ; F#4
	REST L16
	TRIPLET
	NOTE L16, 8       ; E_4
	TRIPLET
	NOTE L8, 9        ; F_4
	NOTE L16, 9       ; F_4
	REST L16
	NOTE L16, 10      ; F#4
	NOTE L16, 11      ; G_4
	REST L16
	DOTTED L8, 12     ; G#4
	DUTY $00
	BASE 44
	NOTE L16, 24      ; G#6
	NOTE L16, 26      ; A#6
	REST L16
	NOTE L16, 23      ; G_6
	NOTE L16, 24      ; G#6
	REST L16
	DUTY $80
	BASE 32
	REST L8
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	NOTE L8, 10       ; F#4
	NOTE L8, 7        ; D#4
	REST L8
	NOTE L16, 10      ; F#4
	NOTE L16, 10      ; F#4
	REST L16
	NOTE L4, 15       ; B_4
	REST L16
	NOTE L16, 14      ; A#4
	REST L16
	NOTE L16, 15      ; B_4
	REST L16
	TRIPLET
	NOTE L8, 14       ; A#4
	TRIPLET
	NOTE L8, 13       ; A_4
	TRIPLET
	NOTE L8, 12       ; G#4
	DUTY $00
	BASE 44
	TRIPLET
	NOTE L16, 16      ; C_6
	TRIPLET
	NOTE L8, 17       ; C#6
	NOTE L16, 19      ; D#6
	NOTE L16, 17      ; C#6
	REST L16
	NOTE L16, 16      ; C_6
	NOTE L16, 15      ; B_5
	NOTE L16, 14      ; A#5
	NOTE L8, 10       ; F#5
	TRIPLET
	NOTE L16, 14      ; A#5
	TRIPLET
	NOTE L8, 15       ; B_5
	NOTE L8, 10       ; F#5
	REST L16
	NOTE L16, 15      ; B_5
	REST L8
	NOTE L16, 19      ; D#6
	REST L16
	TRIPLET
	NOTE L8, 22       ; F#6
	TRIPLET
	NOTE L8, 21       ; F_6
	TRIPLET
	NOTE L8, 19       ; D#6
	NOTE L16, 14      ; A#5
	REST L16
	NOTE L16, 14      ; A#5
	REST L16
	TRIPLET
	NOTE L8, 14       ; A#5
	TRIPLET
	NOTE L8, 13       ; A_5
	TRIPLET
	NOTE L8, 12       ; G#5
	NOTE L16, 19      ; D#6
	REST L16
	NOTE L16, 19      ; D#6
	REST L16
	TRIPLET
	NOTE L8, 19       ; D#6
	TRIPLET
	NOTE L8, 17       ; C#6
	TRIPLET
	NOTE L8, 14       ; A#5
	DUTY $C0
	NOTE L16, 12      ; G#5
	NOTE L16, 12      ; G#5
	REST L16
	NOTE L16, 14      ; A#5
	REST L16
	NOTE L16, 15      ; B_5
	NOTE L16, 16      ; C_6
	REST L16
	NOTE L16, 17      ; C#6
	REST L16
	NOTE L16, 19      ; D#6
	REST L8
	NOTE L16, 14      ; A#5
	NOTE L16, 12      ; G#5
	REST L16
	NOTE L2, 10       ; F#5
	REST L8
	VOLUME $80
	DUTY $80
	ENVELOPE 5
	TRIPLET
	REST L8
	NOTE L8, 29       ; C#7
	NOTE L8, 28       ; C_7
	NOTE L8, 27       ; B_6
	BASE 32
	DUTY $00
	ENVELOPE 2
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L8, 25       ; A_5
	REST L8
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L8, 25       ; A_5
	REST L8
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L8, 25       ; A_5
	NOTE L16, 22      ; F#5
	NOTE L16, 20      ; E_5
	REST L8
	NOTE L8, 22       ; F#5
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 24      ; G#5
	TRIPLET
	NOTE L16, 25      ; A_5
	TRIPLET
	REST L16
	NOTE L16, 22      ; F#5
	NOTE L16, 20      ; E_5
	REST L16
	NOTE L16, 16      ; C_5
	NOTE L16, 15      ; B_4
	NOTE L16, 13      ; A_4
	REST L16
	NOTE L16, 10      ; F#4
	NOTE L16, 8       ; E_4
	NOTE L16, 10      ; F#4
	TRIPLET
	NOTE L16, 22      ; F#5
	TRIPLET
	NOTE L16, 15      ; B_4
	TRIPLET
	NOTE L16, 22      ; F#5
	TRIPLET
	NOTE L16, 15      ; B_4
	TRIPLET
	NOTE L16, 22      ; F#5
	TRIPLET
	NOTE L16, 15      ; B_4
	BASE 44
	NOTE L16, 19      ; D#6
	NOTE L16, 19      ; D#6
	REST L16
	NOTE L16, 19      ; D#6
	NOTE L16, 19      ; D#6
	NOTE L16, 15      ; B_5
	NOTE L16, 19      ; D#6
	REST L16
	NOTE L16, 22      ; F#6
	NOTE L16, 19      ; D#6
	NOTE L16, 15      ; B_5
	NOTE L16, 14      ; A#5
	NOTE L4, 10       ; F#5
	NOTE L8, 13       ; A_5
	NOTE L4, 15       ; B_5
	NOTE L8, 14       ; A#5
	NOTE L8, 20       ; E_6
	TRIPLET
	NOTE L16, 21      ; F_6
	TRIPLET
	NOTE L8, 22       ; F#6
	REST L8
	TRIPLET
	NOTE L16, 21      ; F_6
	TRIPLET
	NOTE L8, 22       ; F#6
	REST L8
	TRIPLET
	NOTE L16, 21      ; F_6
	TRIPLET
	NOTE L8, 22       ; F#6
	REST L8
	NOTE L8, 17       ; C#6
	NOTE L8, 14       ; A#5
	TRIPLET
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L8, 25       ; A_6
	TRIPLET
	NOTE L8, 25       ; A_6
	NOTE L16, 25      ; A_6
	REST L16
	NOTE L16, 22      ; F#6
	NOTE L16, 20      ; E_6
	REST L16
	NOTE L16, 16      ; C_6
	NOTE L16, 15      ; B_5
	NOTE L16, 13      ; A_5
	REST L8
	NOTE L16, 17      ; C#6
	NOTE L16, 17      ; C#6
	REST L16
	NOTE L16, 17      ; C#6
	NOTE L16, 15      ; B_5
	NOTE L16, 17      ; C#6
	NOTE L16, 20      ; E_6
	REST L16
	NOTE L16, 17      ; C#6
	NOTE L16, 15      ; B_5
	REST L16
	NOTE L16, 17      ; C#6
	REST L8
	REST L16
	NOTE L16, 5       ; C#5
	NOTE L16, 10      ; F#5
	NOTE L16, 12      ; G#5
	REST L16
	NOTE L16, 17      ; C#6
	NOTE L16, 22      ; F#6
	NOTE L16, 24      ; G#6
	TRIPLET
	NOTE L8, 29       ; C#7
	TRIPLET
	NOTE L8, 29       ; C#7
	TRIPLET
	NOTE L8, 29       ; C#7
	NOTE L16, 29      ; C#7
	DOTTED L8, 20     ; E_6
	TRIPLET
	REST L16
	GOTO .l510F
Song04_Ch3:
	BASE 32
	VOLUME $20
	REST L2
	NOTE L16, 21      ; F_5
	REST L16
	NOTE L16, 19      ; D#5
	NOTE L16, 17      ; C#5
	REST L8
	NOTE L8, 12       ; G#4
.l5250:
	VOLUME $20
	DOTTED L8, 10     ; F#4
	DOTTED L8, 14     ; A#4
	NOTE L8, 17       ; C#5
	NOTE L16, 10      ; F#4
	NOTE L8, 10       ; F#4
	DOTTED L8, 9      ; F_4
	NOTE L8, 7        ; D#4
	NOTE L16, 5       ; C#4
	REST L16
	NOTE L16, 5       ; C#4
	REST L16
	NOTE L16, 9       ; F_4
	DOTTED L8, 12     ; G#4
	DOTTED L8, 5      ; C#4
	DOTTED L8, 9      ; F_4
	NOTE L8, 4        ; C_4
	DOTTED L8, 3      ; B_3
	DOTTED L8, 7      ; D#4
	NOTE L8, 10       ; F#4
	NOTE L16, 3       ; B_3
	NOTE L16, 3       ; B_3
	REST L16
	DOTTED L8, 7      ; D#4
	NOTE L8, 10       ; F#4
	NOTE L4, 10       ; F#4
	TRIPLET
	NOTE L8, 10       ; F#4
	TRIPLET
	NOTE L8, 14       ; A#4
	TRIPLET
	NOTE L8, 17       ; C#5
	NOTE L8, 10       ; F#4
	NOTE L16, 10      ; F#4
	DOTTED L8, 14     ; A#4
	NOTE L8, 17       ; C#5
	DOTTED L8, 3      ; B_3
	DOTTED L8, 7      ; D#4
	NOTE L8, 10       ; F#4
	NOTE L8, 3        ; B_3
	NOTE L16, 3       ; B_3
	DOTTED L8, 7      ; D#4
	NOTE L8, 10       ; F#4
	DOTTED L8, 10     ; F#4
	DOTTED L8, 14     ; A#4
	NOTE L8, 17       ; C#5
	DOTTED L8, 7      ; D#4
	DOTTED L8, 10     ; F#4
	NOTE L8, 14       ; A#4
	DOTTED L8, 5      ; C#4
	DOTTED L8, 9      ; F_4
	NOTE L8, 12       ; G#4
	DOTTED L8, 15     ; B_4
	DOTTED L8, 7      ; D#4
	NOTE L8, 8        ; E_4
	DOTTED L8, 10     ; F#4
	DOTTED L8, 14     ; A#4
	NOTE L8, 17       ; C#5
	REST L16
	NOTE L16, 5       ; C#4
	NOTE L8, 5        ; C#4
	NOTE L8, 7        ; D#4
	NOTE L8, 9        ; F_4
	VOLUME $20
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	NOTE L4, 10       ; F#4
	NOTE L8, 10       ; F#4
	NOTE L16, 10      ; F#4
	DOTTED L8, 14     ; A#4
	NOTE L8, 17       ; C#5
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	REST L16
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	NOTE L16, 10      ; F#4
	NOTE L8, 14       ; A#4
	NOTE L8, 17       ; C#5
	NOTE L8, 3        ; B_3
	NOTE L8, 3        ; B_3
	NOTE L4, 3        ; B_3
	NOTE L8, 3        ; B_3
	NOTE L16, 3       ; B_3
	DOTTED L8, 7      ; D#4
	NOTE L8, 10       ; F#4
	NOTE L8, 6        ; D_4
	NOTE L8, 6        ; D_4
	NOTE L8, 10       ; F#4
	NOTE L16, 13      ; A_4
	NOTE L8, 8        ; E_4
	NOTE L8, 8        ; E_4
	NOTE L16, 8       ; E_4
	NOTE L8, 12       ; G#4
	NOTE L8, 15       ; B_4
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	NOTE L8, 10       ; F#4
	REST L16
	NOTE L8, 9        ; F_4
	NOTE L8, 9        ; F_4
	NOTE L16, 9       ; F_4
	NOTE L8, 14       ; A#4
	NOTE L8, 17       ; C#5
	NOTE L8, 7        ; D#4
	NOTE L8, 7        ; D#4
	NOTE L8, 7        ; D#4
	REST L16
	NOTE L8, 7        ; D#4
	NOTE L8, 7        ; D#4
	NOTE L16, 7       ; D#4
	NOTE L8, 10       ; F#4
	NOTE L8, 14       ; A#4
	NOTE L8, 6        ; D_4
	NOTE L8, 6        ; D_4
	NOTE L8, 6        ; D_4
	REST L16
	NOTE L8, 6        ; D_4
	NOTE L8, 6        ; D_4
	NOTE L16, 6       ; D_4
	NOTE L8, 10       ; F#4
	NOTE L8, 13       ; A_4
	NOTE L8, 5        ; C#4
	NOTE L8, 5        ; C#4
	NOTE L16, 10      ; F#4
	NOTE L8, 12       ; G#4
	REST L16
	NOTE L16, 11      ; G_4
	DOTTED L8, 11     ; G_4
	NOTE L16, 12      ; G#4
	NOTE L16, 5       ; C#4
	NOTE L16, 7       ; D#4
	NOTE L16, 9       ; F_4
	GOTO .l5250
Song04_Ch4:
	VOLUME $40
	ENVELOPE 5
	NOTE L4, 10
	REST L2
	REST L16
	NOTE L16, 8
	NOTE L8, 7
.l52FF:
	ENVELOPE 3
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L16, 8
	NOTE L8, 13
	NOTE L16, 13
	NOTE L8, 8
	LOOP 2, .l52FF
	NOTE L8, 13
	NOTE L8, 8
	TRIPLET
	NOTE L8, 13
	TRIPLET
	NOTE L8, 8
	TRIPLET
	NOTE L8, 8
	NOTE L8, 13
	NOTE L16, 8
	NOTE L8, 13
	NOTE L16, 13
	NOTE L8, 8
.l531B:
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L16, 8
	NOTE L8, 13
	NOTE L16, 13
	NOTE L8, 8
	LOOP 3, .l531B
.l5328:
	NOTE L8, 13
	NOTE L8, 8
	LOOP 27, .l5328
	NOTE L16, 13
	NOTE L8, 8
	NOTE L16, 13
	NOTE L8, 8
	NOTE L16, 13
	NOTE L16, 7
	TRIPLET
	NOTE L8, 7
	TRIPLET
	NOTE L8, 7
	TRIPLET
	NOTE L8, 7
	NOTE L16, 5
	NOTE L16, 5
	NOTE L8, 5
	GOTO .l52FF
Song04_Vib:
	db $00

;; Song $05 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song05:
	db $02, 1
	dw Song05_Ch1
	dw Song05_Ch2
	dw Song05_Ch3
	dw Song05_Ch4
	dw Song05_Vib
Song05_Ch1:
	BASE 44
	DUTY $C0
	VOLUME $A0
	REST L1
	REST L2
	REST L4
	REST L8
	ENVELOPE 9
	TIE 3
	NOTE L2, 5        ; C#5
	VIBRATO 1
	NOTE L2, 5        ; C#5
	NOTE L8, 5        ; C#5
	VIBRATO 0
	NOTE L4, 10       ; F#5
	NOTE L4, 12       ; G#5
	NOTE L4, 15       ; B_5
	DOTTED L4, 15     ; B_5
	NOTE L8, 14       ; A#5
	TIE 3
	NOTE L4, 14       ; A#5
	NOTE L8, 14       ; A#5
	VIBRATO 1
	NOTE L2, 14       ; A#5
	VIBRATO 0
	NOTE L4, 12       ; G#5
	NOTE L4, 10       ; F#5
	DOTTED L2, 17     ; C#6
	DOTTED L2, 10     ; F#5
	TIE 4
	NOTE L2, 22       ; F#6
	NOTE L4, 22       ; F#6
	VIBRATO 3
	NOTE L1, 22       ; F#6
	NOTE L8, 22       ; F#6
	VIBRATO 0
	NOTE L4, 24       ; G#6
	NOTE L8, 22       ; F#6
	TIE 2
	NOTE L1, 29       ; C#7
	VIBRATO 3
	NOTE L1, 29       ; C#7
	VIBRATO 0
.l5388:
	BASE 32
	DUTY $00
	ENVELOPE 0
	REST L2
	NOTE L8, 14       ; A#4
	NOTE L8, 15       ; B_4
	NOTE L8, 17       ; C#5
	DOTTED L4, 17     ; C#5
	NOTE L4, 22       ; F#5
	NOTE L4, 21       ; F_5
	NOTE L4, 22       ; F#5
	NOTE L4, 24       ; G#5
	NOTE L8, 26       ; A#5
	TIE 4
	NOTE L2, 22       ; F#5
	VIBRATO 4
	NOTE L2, 22       ; F#5
	NOTE L4, 22       ; F#5
	NOTE L8, 22       ; F#5
	VIBRATO 0
	NOTE L8, 21       ; F_5
	NOTE L8, 22       ; F#5
	DOTTED L4, 29     ; C#6
	NOTE L8, 22       ; F#5
	TIE 3
	NOTE L2, 22       ; F#5
	VIBRATO 4
	NOTE L2, 22       ; F#5
	NOTE L4, 22       ; F#5
	VIBRATO 0
	NOTE L8, 22       ; F#5
	NOTE L8, 22       ; F#5
	NOTE L2, 22       ; F#5
	REST L8
	NOTE L8, 24       ; G#5
	NOTE L8, 22       ; F#5
	TIE 3
	NOTE L2, 21       ; F_5
	VIBRATO 4
	NOTE L2, 21       ; F_5
	NOTE L8, 21       ; F_5
	VIBRATO 0
	NOTE L2, 14       ; A#4
	REST L8
	NOTE L8, 12       ; G#4
	NOTE L8, 10       ; F#4
	NOTE L2, 17       ; C#5
	REST L8
	NOTE L4, 22       ; F#5
	NOTE L4, 24       ; G#5
	DOTTED L4, 27     ; B_5
	NOTE L8, 26       ; A#5
	TIE 2
	NOTE L2, 26       ; A#5
	VIBRATO 4
	NOTE L2, 26       ; A#5
	VIBRATO 0
	NOTE L4, 29       ; C#6
	NOTE L4, 27       ; B_5
	NOTE L8, 26       ; A#5
	NOTE L8, 27       ; B_5
	NOTE L8, 26       ; A#5
	NOTE L4, 22       ; F#5
	NOTE L2, 17       ; C#5
	NOTE L8, 24       ; G#5
	NOTE L8, 22       ; F#5
	NOTE L8, 21       ; F_5
	NOTE L8, 19       ; D#5
	DOTTED L4, 21     ; F_5
	NOTE L8, 22       ; F#5
	REST L4
	NOTE L8, 22       ; F#5
	REST L4
	NOTE L4, 22       ; F#5
	IGNORED $01, $FC
	ENVELOPE 8
	NOTE L1, 1        ; A_3
	IGNORED $01, $00
	ENVELOPE 0
	NOTE L8, 22       ; F#5
	NOTE L8, 22       ; F#5
	REST L4
	NOTE L8, 24       ; G#5
	NOTE L8, 24       ; G#5
	REST L8
	NOTE L2, 20       ; E_5
	NOTE L4, 17       ; C#5
	NOTE L8, 20       ; E_5
	TRIPLET
	NOTE L16, 15      ; B_4
	TRIPLET
	NOTE L16, 16      ; C_5
	TRIPLET
	NOTE L16, 15      ; B_4
	NOTE L8, 13       ; A_4
	NOTE L4, 15       ; B_4
	NOTE L8, 13       ; A_4
	NOTE L8, 15       ; B_4
	REST L8
	NOTE L8, 13       ; A_4
	REST L8
	NOTE L1, 17       ; C#5
	REST L8
	NOTE L8, 22       ; F#5
	NOTE L8, 22       ; F#5
	REST L4
	NOTE L8, 24       ; G#5
	NOTE L8, 24       ; G#5
	REST L8
	NOTE L4, 25       ; A_5
	NOTE L4, 20       ; E_5
	NOTE L4, 20       ; E_5
	NOTE L8, 20       ; E_5
	NOTE L8, 25       ; A_5
	TIE 3
	NOTE L2, 27       ; B_5
	NOTE L4, 11       ; G_4
	NOTE L8, 27       ; B_5
	NOTE L8, 25       ; A_5
	DOTTED L2, 29     ; C#6
	NOTE L8, 29       ; C#6
	NOTE L8, 29       ; C#6
	TIE 3
	NOTE L2, 29       ; C#6
	NOTE L8, 29       ; C#6
	VIBRATO 1
	NOTE L1, 13       ; A_4
	VIBRATO 0
	BASE 20
	NOTE L4, 6        ; D_3
	NOTE L4, 8        ; E_3
	GOTO .l5388
Song05_Ch2:
	DUTY $40
	VOLUME $70
	VIBRATO 2
.l542C:
	BASE 44
	NOTE L8, 10       ; F#5
	NOTE L8, 17       ; C#6
	NOTE L8, 22       ; F#6
	NOTE L8, 24       ; G#6
	NOTE L8, 17       ; C#6
	NOTE L8, 22       ; F#6
	NOTE L8, 24       ; G#6
	NOTE L8, 27       ; B_6
	NOTE L8, 17       ; C#6
	NOTE L8, 27       ; B_6
	NOTE L8, 26       ; A#6
	NOTE L8, 17       ; C#6
	NOTE L8, 26       ; A#6
	NOTE L8, 24       ; G#6
	NOTE L8, 22       ; F#6
	LOOP 4, .l542C
.l5441:
	BASE 44
	DUTY $C0
	ENVELOPE 4
	VIBRATO 2
.l5449:
	NOTE L8, 10       ; F#5
	NOTE L8, 17       ; C#6
	NOTE L8, 22       ; F#6
	NOTE L8, 24       ; G#6
	NOTE L8, 17       ; C#6
	NOTE L8, 22       ; F#6
	NOTE L8, 24       ; G#6
	NOTE L8, 17       ; C#6
	NOTE L8, 27       ; B_6
	NOTE L8, 17       ; C#6
	NOTE L8, 27       ; B_6
	NOTE L8, 26       ; A#6
	NOTE L8, 17       ; C#6
	NOTE L8, 26       ; A#6
	NOTE L8, 24       ; G#6
	NOTE L8, 22       ; F#6
	LOOP 7, .l5449
	NOTE L8, 22       ; F#6
	NOTE L8, 13       ; A_5
	NOTE L8, 18       ; D_6
	NOTE L8, 24       ; G#6
	NOTE L8, 15       ; B_5
	NOTE L8, 24       ; G#6
	NOTE L8, 27       ; B_6
	NOTE L8, 26       ; A#6
	NOTE L8, 22       ; F#6
	NOTE L8, 17       ; C#6
	NOTE L8, 15       ; B_5
	NOTE L8, 14       ; A#5
	NOTE L8, 10       ; F#5
	NOTE L8, 5        ; C#5
	NOTE L8, 3        ; B_4
	NOTE L8, 2        ; A#4
	DUTY $00
	ENVELOPE 0
	VIBRATO 0
	NOTE L8, 1        ; A_4
	NOTE L8, 1        ; A_4
	REST L4
	NOTE L8, 3        ; B_4
	NOTE L8, 3        ; B_4
	REST L8
	NOTE L4, 1        ; A_4
	BASE 55
	DUTY $40
	VIBRATO 2
	NOTE L8, 1        ; G#5
	NOTE L8, 2        ; A_5
	NOTE L8, 9        ; E_6
	REST L8
	NOTE L8, 13       ; G#6
	NOTE L8, 14       ; A_6
	NOTE L8, 21       ; E_7
	BASE 32
	DUTY $00
	VIBRATO 0
	NOTE L4, 6        ; D_4
	NOTE L8, 6        ; D_4
	NOTE L8, 6        ; D_4
	REST L8
	NOTE L8, 6        ; D_4
	REST L8
	NOTE L1, 9        ; F_4
	REST L8
	NOTE L8, 18       ; D_5
	NOTE L8, 18       ; D_5
	REST L4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	REST L8
	NOTE L4, 17       ; C#5
	NOTE L4, 17       ; C#5
	NOTE L4, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 20       ; E_5
	DOTTED L2, 22     ; F#5
	REST L8
	NOTE L8, 22       ; F#5
	DOTTED L2, 21     ; F_5
	NOTE L8, 21       ; F_5
	NOTE L8, 21       ; F_5
	NOTE L8, 22       ; F#5
	GOTO .l5441
Song05_Ch3:
	VOLUME $20
	BASE 32
	VIBRATO 0
	REST L1
	REST L2
	REST L4
	REST L8
	DOTTED L4, 10     ; F#4
	DOTTED L4, 17     ; C#5
	NOTE L1, 22       ; F#5
	REST L8
	DOTTED L4, 8      ; E_4
	DOTTED L4, 15     ; B_4
	NOTE L1, 20       ; E_5
	REST L8
	DOTTED L4, 7      ; D#4
	DOTTED L4, 14     ; A#4
	NOTE L1, 19       ; D#5
	REST L8
	DOTTED L4, 6      ; D_4
	DOTTED L4, 13     ; A_4
	NOTE L1, 18       ; D_5
	REST L8
.l54CF:
	NOTE L8, 22       ; F#5
	LOOP 15, .l54CF
.l54D4:
	NOTE L8, 22       ; F#5
	LOOP 7, .l54D4
.l54D9:
	NOTE L8, 21       ; F_5
	LOOP 7, .l54D9
.l54DE:
	NOTE L8, 19       ; D#5
	LOOP 7, .l54DE
.l54E3:
	NOTE L8, 17       ; C#5
	LOOP 7, .l54E3
.l54E8:
	NOTE L8, 15       ; B_4
	LOOP 7, .l54E8
.l54ED:
	NOTE L8, 16       ; C_5
	LOOP 7, .l54ED
.l54F2:
	NOTE L8, 17       ; C#5
	LOOP 15, .l54F2
.l54F7:
	NOTE L8, 22       ; F#5
	LOOP 7, .l54F7
.l54FC:
	NOTE L8, 20       ; E_5
	LOOP 7, .l54FC
.l5501:
	NOTE L8, 19       ; D#5
	LOOP 7, .l5501
.l5506:
	NOTE L8, 18       ; D_5
	LOOP 7, .l5506
.l550B:
	NOTE L8, 17       ; C#5
	LOOP 7, .l550B
	NOTE L8, 16       ; C_5
	NOTE L8, 16       ; C_5
	NOTE L8, 16       ; C_5
	NOTE L8, 16       ; C_5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 18       ; D_5
	REST L4
	NOTE L8, 20       ; E_5
	REST L4
	DOTTED L4, 22     ; F#5
.l551E:
	NOTE L8, 10       ; F#4
	LOOP 6, .l551E
.l5523:
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	REST L4
	NOTE L8, 20       ; E_5
	NOTE L8, 20       ; E_5
	REST L8
	NOTE L4, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 13       ; A_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 15       ; B_4
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	NOTE L8, 17       ; C#5
	LOOP 1, .l5523
.l5545:
	NOTE L8, 18       ; D_5
	LOOP 8, .l5545
	REST L8
	REST L4
	NOTE L4, 18       ; D_5
	NOTE L4, 20       ; E_5
	GOTO .l54D4
Song05_Ch4:
	REST L8
	LOOP 70, Song05_Ch4
	VOLUME $40
	ENVELOPE 4
	NOTE L8, 10
	NOTE L8, 15
	NOTE L8, 10
	NOTE L8, 15
.l555F:
	ENVELOPE 4
	NOTE L8, 15
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 4
	NOTE L8, 10
	ENVELOPE 2
	NOTE L8, 3
	LOOP 2, .l555F
	ENVELOPE 4
	NOTE L8, 15
	ENVELOPE 2
	NOTE L8, 3
	ENVELOPE 4
	NOTE L8, 10
	NOTE L8, 10
	GOTO .l555F
Song05_Vib:
	db $00, $42, $00, $22, $62

;; Song $06 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song06:
	db $10, 0
	dw Song06_Ch1
	dw Song06_Ch2
	dw Song06_Ch3
	dw $0000
	dw Song06_Vib
Song06_Ch1:
	VOLUME $A0
.l5590:
	BASE 35
	DUTY $80
	NOTE L8, 22       ; A_5
	NOTE L8, 17       ; E_5
	NOTE L8, 21       ; G#5
	NOTE L8, 22       ; A_5
	NOTE L8, 17       ; E_5
	NOTE L8, 21       ; G#5
	NOTE L8, 22       ; A_5
	NOTE L8, 17       ; E_5
	GOTO .l5590
Song06_Ch2:
	VOLUME $60
	TRIPLET
	REST L8
	GOTO Song06_Ch1.l5590
Song06_Ch3:
	VOLUME $20
	BASE 35
.l55AC:
	DOTTED L4, 14     ; C#5
	TIE 2
	NOTE L2, 15       ; D_5
	NOTE L8, 15       ; D_5
	DOTTED L4, 17     ; E_5
	TIE 2
	NOTE L2, 15       ; D_5
	NOTE L8, 15       ; D_5
	GOTO .l55AC
Song06_Vib:
	db $00

;; Song $07 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song07:
	db $07, 0
	dw Song07_Ch1
	dw Song07_Ch2
	dw Song07_Ch3
	dw Song07_Ch4
	dw Song07_Vib
Song07_Ch1:
	DUTY $00
	VOLUME $F0
	ENVELOPE 5
	BASE 6
	NOTE L8, 10       ; E_2
	NOTE L8, 13       ; G_2
	NOTE L16, 10      ; E_2
	NOTE L16, 8       ; D_2
	NOTE L8, 9        ; D#2
	NOTE L8, 10       ; E_2
	NOTE L8, 13       ; G_2
	REST L8
	NOTE L8, 15       ; A_2
	REST L8
	NOTE L8, 16       ; A#2
	REST L8
	NOTE L8, 17       ; B_2
	REST L8
	NOTE L8, 17       ; B_2
	NOTE L16, 16      ; A#2
	NOTE L16, 15      ; A_2
	NOTE L8, 13       ; G_2
.l55E1:
	NOTE L8, 10       ; E_2
	NOTE L8, 13       ; G_2
	NOTE L16, 10      ; E_2
	NOTE L16, 8       ; D_2
	NOTE L8, 9        ; D#2
	NOTE L8, 10       ; E_2
	NOTE L8, 13       ; G_2
	REST L8
	NOTE L8, 15       ; A_2
	REST L8
	NOTE L8, 16       ; A#2
	REST L8
	NOTE L8, 17       ; B_2
	REST L8
	NOTE L8, 17       ; B_2
	NOTE L16, 16      ; A#2
	NOTE L16, 15      ; A_2
	NOTE L8, 13       ; G_2
	LOOP 1, .l55E1
.l55F7:
	NOTE L8, 15       ; A_2
	NOTE L8, 18       ; C_3
	NOTE L16, 15      ; A_2
	NOTE L16, 13      ; G_2
	NOTE L8, 14       ; G#2
	NOTE L8, 15       ; A_2
	NOTE L8, 18       ; C_3
	REST L8
	NOTE L8, 20       ; D_3
	REST L8
	NOTE L8, 21       ; D#3
	REST L8
	NOTE L8, 22       ; E_3
	REST L8
	NOTE L8, 22       ; E_3
	NOTE L16, 21      ; D#3
	NOTE L16, 20      ; D_3
	NOTE L8, 18       ; C_3
	LOOP 1, .l55F7
	GOTO .l55E1
Song07_Ch2:
	ENVELOPE 5
	DUTY $80
	VOLUME $F0
	BASE 54
	REST L1
	REST L2
	TRIPLET
	NOTE L16, 29      ; B_7
	TRIPLET
	NOTE L16, 27      ; A_7
	TRIPLET
	NOTE L16, 25      ; G_7
	TRIPLET
	NOTE L16, 24      ; F#7
	TRIPLET
	NOTE L16, 22      ; E_7
	TRIPLET
	NOTE L16, 20      ; D_7
	TRIPLET
	NOTE L16, 18      ; C_7
	TRIPLET
	NOTE L16, 17      ; B_6
	TRIPLET
	NOTE L16, 15      ; A_6
	TRIPLET
	NOTE L16, 13      ; G_6
	TRIPLET
	NOTE L16, 12      ; F#6
	TRIPLET
	NOTE L16, 10      ; E_6
.l5633:
	VOLUME $C0
	ENVELOPE 1
	BASE 42
	DUTY $00
	NOTE L16, 17      ; B_5
	NOTE L16, 17      ; B_5
	REST L16
	LOOP 7, .l5633
	NOTE L16, 10      ; E_5
	NOTE L16, 9       ; D#5
	NOTE L16, 8       ; D_5
	NOTE L16, 5       ; B_4
	NOTE L16, 3       ; A_4
	NOTE L16, 4       ; A#4
	NOTE L16, 5       ; B_4
	REST L16
	DUTY $80
	VOLUME $70
	TRIPLET
	REST L8
	NOTE L16, 10      ; E_5
	NOTE L16, 8       ; D_5
	NOTE L16, 10      ; E_5
	NOTE L16, 13      ; G_5
	REST L8
	NOTE L16, 10      ; E_5
	NOTE L16, 13      ; G_5
	NOTE L16, 16      ; A#5
	NOTE L16, 15      ; A_5
	TRIPLET
	REST L16
	DUTY $00
	VOLUME $C0
	NOTE L16, 17      ; B_5
	NOTE L16, 17      ; B_5
	REST L8
	DUTY $80
	VOLUME $70
	TRIPLET
	REST L8
	NOTE L16, 22      ; E_6
	REST L16
	NOTE L16, 16      ; A#5
	REST L16
	NOTE L16, 15      ; A_5
	NOTE L16, 13      ; G_5
	NOTE L16, 10      ; E_5
	NOTE L16, 8       ; D_5
	REST L8
	NOTE L16, 9       ; D#5
	REST L16
	NOTE L16, 10      ; E_5
	NOTE L16, 5       ; B_4
	TRIPLET
	NOTE L16, 3       ; A_4
.l5677:
	DUTY $00
	VOLUME $C0
	NOTE L16, 22      ; E_6
	NOTE L16, 22      ; E_6
	REST L16
	LOOP 2, .l5677
	REST L16
	DUTY $80
	VOLUME $70
	TRIPLET
	REST L8
	NOTE L16, 15      ; A_5
	REST L16
	NOTE L16, 18      ; C_6
	NOTE L16, 15      ; A_5
	TRIPLET
	NOTE L16, 13      ; G_5
	DUTY $00
	VOLUME $C0
	NOTE L16, 6       ; C_5
	NOTE L16, 6       ; C_5
	REST L8
	NOTE L16, 10      ; E_5
	NOTE L16, 10      ; E_5
	REST L8
	NOTE L16, 15      ; A_5
	NOTE L16, 15      ; A_5
	REST L8
	NOTE L16, 18      ; C_6
	NOTE L16, 18      ; C_6
	REST L8
	DUTY $80
	VOLUME $70
	TRIPLET
	REST L8
	NOTE L16, 22      ; E_6
	REST L16
	NOTE L16, 18      ; C_6
	NOTE L16, 15      ; A_5
	REST L8
	NOTE L16, 25      ; G_6
	REST L16
	NOTE L16, 22      ; E_6
	NOTE L16, 18      ; C_6
	REST L8
	NOTE L16, 27      ; A_6
	REST L16
	TRIPLET
	NOTE L16, 24      ; F#6
	DUTY $00
	VOLUME $C0
	NOTE L4, 10       ; E_5
	NOTE L4, 8        ; D_5
	NOTE L4, 10       ; E_5
	NOTE L4, 12       ; F#5
	GOTO .l5633
Song07_Ch3:
	VOLUME $20
	BASE 6
	NOTE L8, 10       ; E_2
	NOTE L8, 13       ; G_2
	NOTE L16, 10      ; E_2
	NOTE L16, 8       ; D_2
	NOTE L8, 9        ; D#2
	NOTE L8, 10       ; E_2
	NOTE L8, 13       ; G_2
	REST L8
	NOTE L8, 15       ; A_2
	REST L8
	NOTE L8, 16       ; A#2
	REST L8
	NOTE L8, 17       ; B_2
	REST L8
	NOTE L8, 17       ; B_2
	NOTE L16, 16      ; A#2
	NOTE L16, 15      ; A_2
	NOTE L8, 13       ; G_2
.l56D5:
	VOLUME $20
	BASE 54
	NOTE L16, 20      ; D_7
	NOTE L16, 20      ; D_7
	REST L16
	LOOP 7, .l56D5
	NOTE L16, 16      ; A#6
	NOTE L16, 15      ; A_6
	NOTE L16, 13      ; G_6
	NOTE L16, 10      ; E_6
	NOTE L16, 8       ; D_6
	NOTE L16, 9       ; D#6
	NOTE L16, 10      ; E_6
	REST L16
	NOTE L16, 10      ; E_6
	NOTE L16, 8       ; D_6
	NOTE L16, 10      ; E_6
	NOTE L16, 13      ; G_6
	REST L8
	NOTE L16, 10      ; E_6
	NOTE L16, 13      ; G_6
	NOTE L16, 16      ; A#6
	NOTE L16, 15      ; A_6
	REST L8
	NOTE L16, 22      ; E_7
	NOTE L16, 22      ; E_7
	REST L8
	NOTE L16, 22      ; E_7
	REST L16
	NOTE L16, 16      ; A#6
	REST L16
	NOTE L16, 15      ; A_6
	NOTE L16, 13      ; G_6
	NOTE L16, 10      ; E_6
	NOTE L16, 8       ; D_6
	REST L8
	NOTE L16, 9       ; D#6
	REST L16
	NOTE L16, 10      ; E_6
	NOTE L16, 5       ; B_5
	NOTE L16, 3       ; A_5
	REST L16
.l5704:
	NOTE L16, 27      ; A_7
	NOTE L16, 27      ; A_7
	REST L16
	LOOP 2, .l5704
	REST L16
	NOTE L16, 15      ; A_6
	REST L16
	NOTE L16, 18      ; C_7
	NOTE L16, 15      ; A_6
	NOTE L16, 13      ; G_6
	REST L16
	NOTE L16, 15      ; A_6
	NOTE L16, 15      ; A_6
	REST L8
	NOTE L16, 18      ; C_7
	NOTE L16, 18      ; C_7
	REST L8
	NOTE L16, 22      ; E_7
	NOTE L16, 22      ; E_7
	REST L8
	NOTE L16, 27      ; A_7
	NOTE L16, 27      ; A_7
	REST L8
	NOTE L16, 22      ; E_7
	REST L16
	NOTE L16, 18      ; C_7
	NOTE L16, 15      ; A_6
	REST L8
	NOTE L16, 25      ; G_7
	REST L16
	NOTE L16, 22      ; E_7
	NOTE L16, 18      ; C_7
	REST L8
	NOTE L16, 27      ; A_7
	REST L16
	NOTE L16, 24      ; F#7
	NOTE L16, 20      ; D_7
	VOLUME $20
	NOTE L4, 13       ; G_6
	NOTE L4, 12       ; F#6
	NOTE L4, 13       ; G_6
	NOTE L4, 15       ; A_6
	GOTO .l56D5
Song07_Ch4:
	VOLUME $30
	ENVELOPE 5
	REST L4
	NOTE L4, 10
	REST L4
	NOTE L4, 10
	ENVELOPE 2
	NOTE L16, 3
	NOTE L16, 3
	NOTE L16, 3
	NOTE L16, 3
	ENVELOPE 5
	NOTE L4, 10
	ENVELOPE 2
	NOTE L16, 3
	NOTE L16, 3
	ENVELOPE 5
	NOTE L8, 10
	NOTE L16, 9
	NOTE L16, 8
	NOTE L8, 8
.l5751:
	ENVELOPE 4
	NOTE L8, 13
	NOTE L8, 13
	NOTE L4, 10
	REST L8
	NOTE L8, 13
	NOTE L4, 10
	REST L8
	NOTE L8, 13
	NOTE L8, 10
	NOTE L8, 13
	REST L8
	NOTE L8, 10
	NOTE L16, 9
	NOTE L16, 9
	NOTE L8, 9
	LOOP 2, .l5751
	NOTE L8, 13
	NOTE L8, 13
	NOTE L4, 10
	REST L8
	NOTE L8, 13
	NOTE L4, 10
	NOTE L8, 13
	REST L8
	NOTE L4, 10
	NOTE L16, 9
	NOTE L16, 9
	REST L16
	NOTE L16, 9
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 8
	NOTE L16, 8
	GOTO .l5751
Song07_Vib:
	db $00

;; Song $08 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song08:
	db $03, 0
	dw Song08_Ch1
	dw Song08_Ch2
	dw Song08_Ch3
	dw Song08_Ch4
	dw Song08_Vib
Song08_Ch1:
	REST L2
	REST L2
	BASE 35
	DUTY $C0
	ENVELOPE 0
	VOLUME $F0
	NOTE L16, 5       ; E_4
	REST L16
	NOTE L16, 9       ; G#4
	REST L16
	NOTE L16, 12      ; B_4
	REST L16
	NOTE L16, 14      ; C#5
	REST L16
	NOTE L8, 15       ; D_5
	TRIPLET
	NOTE L8, 15       ; D_5
	TRIPLET
	NOTE L16, 14      ; C#5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 12      ; B_4
	NOTE L8, 10       ; A_4
.l57A4:
	NOTE L8, 10       ; A_4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 9       ; G#4
	NOTE L8, 9        ; G#4
	REST L8
	LOOP 1, .l57A4
	NOTE L16, 5       ; E_4
	REST L16
	NOTE L16, 9       ; G#4
	REST L16
	NOTE L16, 12      ; B_4
	REST L16
	NOTE L16, 14      ; C#5
	REST L16
	NOTE L8, 15       ; D_5
	TRIPLET
	NOTE L8, 15       ; D_5
	TRIPLET
	NOTE L16, 14      ; C#5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 12      ; B_4
	NOTE L8, 10       ; A_4
.l57C2:
	NOTE L8, 15       ; D_5
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 14      ; C#5
	NOTE L8, 14       ; C#5
	REST L8
	LOOP 1, .l57C2
	REST L8
	NOTE L8, 7        ; F#4
	NOTE L8, 10       ; A_4
	NOTE L8, 14       ; C#5
	NOTE L16, 14      ; C#5
	REST L16
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 12      ; B_4
	NOTE L8, 12       ; B_4
	REST L4
	NOTE L8, 14       ; C#5
	NOTE L8, 17       ; E_5
	NOTE L8, 19       ; F#5
	NOTE L16, 21      ; G#5
	REST L16
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 19      ; F#5
	NOTE L8, 3        ; D_4
	REST L8
.l57E7:
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L8, 24       ; B_5
	NOTE L16, 21      ; G#5
	REST L16
	REST L8
	REST L4
	DUTY $C0
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 13      ; C_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	LOOP 1, .l57E7
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	REST L4
	BASE 47
	ENVELOPE 5
	DUTY $80
	NOTE L16, 17      ; E_6
	REST L16
	NOTE L16, 19      ; F#6
	REST L16
	NOTE L16, 21      ; G#6
	REST L16
	NOTE L16, 24      ; B_6
	REST L16
	ENVELOPE 7
	BASE 35
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L16, 21      ; G#5
	REST L16
	NOTE L8, 17       ; E_5
	DUTY $00
	NOTE L8, 12       ; B_4
	NOTE L8, 12       ; B_4
	NOTE L8, 14       ; C#5
	NOTE L8, 17       ; E_5
	DUTY $80
	REST L8
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L16, 21      ; G#5
	REST L16
	NOTE L8, 17       ; E_5
	DUTY $00
	NOTE L8, 21       ; G#5
	NOTE L8, 22       ; A_5
	NOTE L8, 21       ; G#5
	NOTE L8, 17       ; E_5
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L8, 19       ; F#5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	REST L8
	NOTE L8, 21       ; G#5
	NOTE L8, 23       ; A#5
	NOTE L8, 21       ; G#5
	NOTE L8, 19       ; F#5
	NOTE L8, 21       ; G#5
.l585B:
	ENVELOPE 0
	DUTY $C0
	NOTE L16, 19      ; F#5
	REST L16
	NOTE L16, 19      ; F#5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 19      ; F#5
	NOTE L8, 26       ; C#6
	NOTE L16, 23      ; A#5
	REST L16
	REST L8
	REST L4
	DUTY $C0
	NOTE L16, 19      ; F#5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 19      ; F#5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	NOTE L16, 15      ; D_5
	REST L16
	NOTE L16, 17      ; E_5
	REST L16
	LOOP 2, .l585B
	NOTE L16, 19      ; F#5
	REST L16
	NOTE L16, 19      ; F#5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 19      ; F#5
	NOTE L8, 26       ; C#6
	NOTE L16, 23      ; A#5
	REST L16
	DUTY $00
	NOTE L16, 23      ; A#5
	REST L16
	REST L4
	GOTO Song08_Ch1
Song08_Ch2:
	REST L2
	REST L2
	DUTY $C0
	ENVELOPE 0
	VOLUME $C0
	BASE 23
	NOTE L16, 5       ; E_3
	REST L16
	NOTE L16, 9       ; G#3
	REST L16
	NOTE L16, 12      ; B_3
	REST L16
	NOTE L16, 14      ; C#4
	REST L16
	NOTE L8, 15       ; D_4
	TRIPLET
	NOTE L8, 15       ; D_4
	TRIPLET
	NOTE L16, 14      ; C#4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 12      ; B_3
	NOTE L8, 10       ; A_3
.l58B6:
	NOTE L8, 19       ; F#4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 17      ; E_4
	NOTE L8, 17       ; E_4
	REST L8
	LOOP 1, .l58B6
	NOTE L16, 5       ; E_3
	REST L16
	NOTE L16, 9       ; G#3
	REST L16
	NOTE L16, 12      ; B_3
	REST L16
	NOTE L16, 14      ; C#4
	REST L16
	NOTE L8, 15       ; D_4
	TRIPLET
	NOTE L8, 15       ; D_4
	TRIPLET
	NOTE L16, 14      ; C#4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 12      ; B_3
	NOTE L8, 10       ; A_3
.l58D4:
	NOTE L8, 22       ; A_4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 22      ; A_4
	NOTE L8, 22       ; A_4
	REST L8
	LOOP 1, .l58D4
	DUTY $00
	ENVELOPE 0
	VOLUME $70
	NOTE L2, 7        ; F#3
	VOLUME $80
	TIE 2
	NOTE L4, 12       ; B_3
	TRIPLET
	NOTE L8, 12       ; B_3
	VOLUME $90
	TRIPLET
	NOTE L16, 12      ; B_3
	TRIPLET
	NOTE L8, 14       ; C#4
	VOLUME $A0
	TIE 4
	TRIPLET
	NOTE L16, 17      ; E_4
	NOTE L4, 17       ; E_4
	VIBRATO 1
	VOLUME $B0
	NOTE L2, 17       ; E_4
	TRIPLET
	NOTE L8, 17       ; E_4
	VOLUME $C0
	VIBRATO 0
	TRIPLET
	NOTE L16, 17      ; E_4
	TRIPLET
	NOTE L16, 21      ; G#4
	TRIPLET
	NOTE L16, 24      ; B_4
	TRIPLET
	NOTE L16, 26      ; C#5
	VOLUME $70
	BASE 35
	NOTE L16, 12      ; B_4
	REST L16
	NOTE L16, 12      ; B_4
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 12      ; B_4
	NOTE L8, 21       ; G#5
	NOTE L16, 17      ; E_5
	REST L16
	VOLUME $C0
	DUTY $00
	NOTE L16, 5       ; E_4
	REST L16
	TRIPLET
	NOTE L8, 9        ; G#4
	TRIPLET
	NOTE L16, 12      ; B_4
	TRIPLET
	NOTE L8, 14       ; C#5
	TIE 4
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L4, 17       ; E_5
	VIBRATO 1
	NOTE L2, 17       ; E_5
	TRIPLET
	NOTE L8, 17       ; E_5
	VIBRATO 0
	TRIPLET
	NOTE L16, 20      ; G_5
	NOTE L8, 19       ; F#5
	VOLUME $60
	NOTE L16, 12      ; B_4
	REST L16
	NOTE L16, 12      ; B_4
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 12      ; B_4
	NOTE L8, 21       ; G#5
	NOTE L16, 17      ; E_5
	REST L16
	VOLUME $C0
	DUTY $00
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 20      ; G_5
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	NOTE L8, 15       ; D_5
	TIE 4
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L4, 17       ; E_5
	VIBRATO 1
	NOTE L2, 17       ; E_5
	TRIPLET
	NOTE L8, 17       ; E_5
	VIBRATO 0
	TRIPLET
	NOTE L16, 13      ; C_5
	NOTE L8, 15       ; D_5
	VOLUME $60
	NOTE L16, 12      ; B_4
	REST L16
	NOTE L16, 12      ; B_4
	REST L16
	REST L4
	ENVELOPE 5
	DUTY $80
	BASE 47
	TRIPLET
	REST L8
	NOTE L16, 17      ; E_6
	REST L16
	NOTE L16, 19      ; F#6
	REST L16
	NOTE L16, 21      ; G#6
	REST L16
	NOTE L16, 24      ; B_6
	REST L16
	ENVELOPE 7
	BASE 35
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L16, 21      ; G#5
	REST L16
	NOTE L8, 17       ; E_5
	DUTY $00
	NOTE L8, 12       ; B_4
	NOTE L8, 12       ; B_4
	NOTE L8, 14       ; C#5
	NOTE L8, 17       ; E_5
	DUTY $80
	REST L8
	TRIPLET
	NOTE L16, 17      ; E_5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 17      ; E_5
	NOTE L16, 21      ; G#5
	REST L16
	NOTE L8, 17       ; E_5
	DUTY $00
	NOTE L8, 21       ; G#5
	NOTE L8, 22       ; A_5
	NOTE L8, 21       ; G#5
	NOTE L8, 17       ; E_5
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L8, 19       ; F#5
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	REST L8
	NOTE L8, 21       ; G#5
	NOTE L8, 23       ; A#5
	NOTE L8, 21       ; G#5
	NOTE L8, 19       ; F#5
	TRIPLET
	NOTE L16, 21      ; G#5
	ENVELOPE 0
	VOLUME $70
	NOTE L16, 14      ; C#5
	REST L16
	NOTE L16, 14      ; C#5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 14      ; C#5
	NOTE L8, 23       ; A#5
	NOTE L16, 19      ; F#5
	REST L16
	VOLUME $C0
	DUTY $00
	NOTE L16, 7       ; F#4
	REST L16
	TRIPLET
	NOTE L8, 11       ; A#4
	TRIPLET
	NOTE L16, 14      ; C#5
	TRIPLET
	NOTE L8, 16       ; D#5
	TIE 4
	TRIPLET
	NOTE L16, 19      ; F#5
	NOTE L4, 19       ; F#5
	VIBRATO 1
	NOTE L2, 19       ; F#5
	TRIPLET
	NOTE L8, 19       ; F#5
	VIBRATO 0
	TRIPLET
	NOTE L16, 22      ; A_5
	NOTE L8, 21       ; G#5
	ENVELOPE 0
	VOLUME $70
	NOTE L16, 14      ; C#5
	REST L16
	NOTE L16, 14      ; C#5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 14      ; C#5
	NOTE L8, 23       ; A#5
	NOTE L16, 19      ; F#5
	REST L16
	VOLUME $C0
	DUTY $00
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 22      ; A_5
	TRIPLET
	NOTE L16, 21      ; G#5
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L8, 17       ; E_5
	TIE 4
	TRIPLET
	NOTE L16, 19      ; F#5
	NOTE L4, 19       ; F#5
	VIBRATO 1
	NOTE L2, 19       ; F#5
	TRIPLET
	NOTE L8, 19       ; F#5
	VIBRATO 0
	TRIPLET
	NOTE L16, 15      ; D_5
	NOTE L8, 17       ; E_5
	VOLUME $60
	NOTE L16, 14      ; C#5
	REST L16
	NOTE L16, 14      ; C#5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 14      ; C#5
	NOTE L8, 23       ; A#5
	TRIPLET
	NOTE L8, 19       ; F#5
	DUTY $00
	VOLUME $C0
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L8, 21       ; G#5
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L8, 23       ; A#5
	TRIPLET
	NOTE L16, 26      ; C#6
	REST L8
	REST L8
	NOTE L8, 19       ; F#5
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 19      ; F#5
	TRIPLET
	NOTE L8, 21       ; G#5
	TRIPLET
	NOTE L16, 19      ; F#5
	TIE 2
	NOTE L4, 24       ; B_5
	TRIPLET
	NOTE L8, 24       ; B_5
	TRIPLET
	NOTE L16, 19      ; F#5
	NOTE L8, 22       ; A_5
	VOLUME $60
	NOTE L16, 14      ; C#5
	REST L16
	NOTE L16, 14      ; C#5
	REST L16
	DUTY $80
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 14      ; C#5
	NOTE L8, 23       ; A#5
	NOTE L16, 19      ; F#5
	REST L16
	DUTY $00
	VOLUME $C0
	NOTE L16, 19      ; F#5
	REST L16
	REST L4
	GOTO Song08_Ch2
Song08_Ch3:
	BASE 35
.l5A5D:
	VOLUME $20
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L16, 5       ; E_4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 5       ; E_4
	NOTE L8, 17       ; E_5
	LOOP 3, .l5A5D
	NOTE L8, 10       ; A_4
	NOTE L8, 22       ; A_5
	NOTE L8, 10       ; A_4
	NOTE L8, 22       ; A_5
	TRIPLET
	NOTE L8, 10       ; A_4
	REST L8
	TRIPLET
	NOTE L8, 10       ; A_4
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 9       ; G#4
	TRIPLET
	NOTE L8, 8        ; G_4
	TRIPLET
	REST L16
.l5A82:
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	TRIPLET
	NOTE L8, 12       ; B_4
	REST L8
	TRIPLET
	NOTE L8, 12       ; B_4
	TRIPLET
	REST L16
	TRIPLET
	NOTE L16, 10      ; A_4
	TRIPLET
	NOTE L8, 9        ; G#4
	TRIPLET
	REST L16
	LOOP 1, .l5A82
.l5A97:
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L16, 5       ; E_4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 5       ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 1        ; C_4
	NOTE L8, 13       ; C_5
	NOTE L8, 1        ; C_4
	NOTE L8, 13       ; C_5
	NOTE L8, 3        ; D_4
	NOTE L8, 15       ; D_5
	NOTE L8, 3        ; D_4
	NOTE L8, 15       ; D_5
	LOOP 1, .l5A97
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	NOTE L8, 7        ; F#4
	NOTE L8, 9        ; G#4
	NOTE L8, 12       ; B_4
	VOLUME $20
	NOTE L8, 10       ; A_4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 7       ; F#4
	NOTE L4, 7        ; F#4
	NOTE L8, 9        ; G#4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 9       ; G#4
	NOTE L4, 9        ; G#4
	NOTE L8, 3        ; D_4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 3       ; D_4
	NOTE L4, 3        ; D_4
	NOTE L8, 5        ; E_4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 5       ; E_4
	NOTE L4, 5        ; E_4
	NOTE L8, 2        ; C#4
	TRIPLET
	REST L8
	TIE 2
	TRIPLET
	NOTE L16, 2       ; C#4
	NOTE L4, 2        ; C#4
	VOLUME $20
	NOTE L8, 14       ; C#5
	NOTE L8, 14       ; C#5
	NOTE L8, 14       ; C#5
	NOTE L8, 14       ; C#5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	NOTE L8, 7        ; F#4
	TRIPLET
	NOTE L8, 19       ; F#5
	TRIPLET
	NOTE L16, 7       ; F#4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 7       ; F#4
	NOTE L8, 19       ; F#5
.l5AF2:
	NOTE L8, 3        ; D_4
	NOTE L8, 15       ; D_5
	NOTE L8, 3        ; D_4
	NOTE L8, 15       ; D_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	NOTE L8, 7        ; F#4
	TRIPLET
	NOTE L8, 19       ; F#5
	TRIPLET
	NOTE L16, 7       ; F#4
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 7       ; F#4
	NOTE L8, 19       ; F#5
	LOOP 1, .l5AF2
	NOTE L8, 3        ; D_4
	NOTE L8, 15       ; D_5
	NOTE L8, 3        ; D_4
	NOTE L8, 15       ; D_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 5        ; E_4
	NOTE L8, 17       ; E_5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	NOTE L8, 7        ; F#4
	NOTE L8, 19       ; F#5
	REST L8
	NOTE L8, 7        ; F#4
	REST L4
	GOTO .l5A5D
Song08_Ch4:
	VOLUME $40
.l5B21:
	ENVELOPE 3
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	TRIPLET
	NOTE L8, 8
	TRIPLET
	NOTE L16, 13
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 5
	NOTE L8, 4
.l5B31:
	NOTE L8, 13
	NOTE L8, 8
	LOOP 21, .l5B31
	NOTE L8, 6
	TRIPLET
	NOTE L8, 3
	NOTE L8, 4
	TRIPLET
	NOTE L16, 5
	NOTE L8, 6
.l5B3E:
	NOTE L8, 13
	NOTE L8, 8
	LOOP 13, .l5B3E
	NOTE L8, 13
	TRIPLET
	NOTE L8, 3
	NOTE L8, 4
	TRIPLET
	NOTE L16, 5
	NOTE L8, 5
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	TRIPLET
	NOTE L8, 13
	TRIPLET
	NOTE L16, 3
	TRIPLET
	NOTE L8, 4
	TRIPLET
	NOTE L16, 4
	TRIPLET
	NOTE L8, 5
	TRIPLET
	NOTE L16, 5
	TRIPLET
	NOTE L16, 6
	TRIPLET
	REST L8
.l5B5F:
	NOTE L8, 13
	TRIPLET
	NOTE L8, 8
	TRIPLET
	NOTE L16, 13
	TRIPLET
	REST L8
	TRIPLET
	NOTE L16, 13
	NOTE L8, 8
	LOOP 3, .l5B5F
.l5B6D:
	NOTE L8, 13
	NOTE L8, 8
	LOOP 3, .l5B6D
.l5B73:
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	TRIPLET
	NOTE L8, 8
	NOTE L8, 13
	TRIPLET
	NOTE L16, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	NOTE L8, 13
	NOTE L8, 8
	LOOP 2, .l5B73
	NOTE L8, 13
	NOTE L8, 8
	TRIPLET
	NOTE L8, 3
	TRIPLET
	NOTE L16, 10
	TRIPLET
	NOTE L16, 4
	TRIPLET
	NOTE L16, 4
	TRIPLET
	NOTE L16, 5
	NOTE L8, 13
	NOTE L8, 8
	REST L4
	GOTO .l5B21
Song08_Vib:
	db $00, $42

;; Song $09 header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song09:
	db $07, 0
	dw Song09_Ch1
	dw Song09_Ch2
	dw Song09_Ch3
	dw $0000
	dw Song09_Vib
Song09_Ch1:
	BASE 35
	VOLUME $C0
	DUTY $C0
.l5BB1:
	NOTE L16, 24      ; B_5
	NOTE L16, 24      ; B_5
	NOTE L16, 21      ; G#5
	NOTE L16, 17      ; E_5
	NOTE L16, 22      ; A_5
	NOTE L16, 22      ; A_5
	NOTE L16, 19      ; F#5
	NOTE L16, 15      ; D_5
	NOTE L16, 17      ; E_5
	NOTE L16, 17      ; E_5
	NOTE L16, 21      ; G#5
	NOTE L16, 21      ; G#5
	NOTE L16, 22      ; A_5
	NOTE L16, 22      ; A_5
	NOTE L16, 23      ; A#5
	NOTE L16, 23      ; A#5
	GOTO .l5BB1
Song09_Ch2:
	VOLUME $B0
	BASE 35
	DUTY $C0
	NOTE L16, 17      ; E_5
	NOTE L16, 17      ; E_5
	NOTE L16, 12      ; B_4
	NOTE L16, 9       ; G#4
	NOTE L16, 15      ; D_5
	NOTE L16, 15      ; D_5
	NOTE L16, 10      ; A_4
	NOTE L16, 7       ; F#4
	VOLUME $E0
	DUTY $80
	BASE 59
	NOTE L16, 21      ; G#7
	NOTE L16, 21      ; G#7
	REST L16
	NOTE L16, 21      ; G#7
	NOTE L16, 21      ; G#7
	REST L16
	NOTE L16, 21      ; G#7
	REST L16
	GOTO Song09_Ch2
Song09_Ch3:
	BASE 35
	VOLUME $20
.l5BE9:
	NOTE L16, 5       ; E_4
	NOTE L16, 17      ; E_5
	NOTE L16, 5       ; E_4
	NOTE L16, 17      ; E_5
	NOTE L16, 3       ; D_4
	NOTE L16, 15      ; D_5
	NOTE L16, 3       ; D_4
	NOTE L16, 15      ; D_5
	GOTO .l5BE9
Song09_Vib:
	db $00

;; Song $0A header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song0A:
	db $03, 1
	dw Song0A_Ch1
	dw Song0A_Ch2
	dw Song0A_Ch3
	dw $0000
	dw Song0A_Vib
Song0A_Ch1:
	BASE 35
	VOLUME $F0
	NOTE L8, 5        ; E_4
	REST L8
	NOTE L8, 5        ; E_4
	REST L4
	DUTY $80
	TRIPLET
	NOTE L8, 17       ; E_5
	TRIPLET
	NOTE L4, 24       ; B_5
	NOTE L8, 21       ; G#5
	REST L4
	DUTY $C0
	NOTE L4, 2        ; C#4
	TIE 2
	NOTE L4, 3        ; D_4
	VIBRATO 1
	NOTE L4, 3        ; D_4
	MUS_END
Song0A_Ch2:
	BASE 23
	VOLUME $C0
	NOTE L8, 9        ; G#3
	REST L8
	NOTE L8, 9        ; G#3
	REST L4
	DUTY $80
	TRIPLET
	NOTE L8, 21       ; G#4
	TRIPLET
	NOTE L4, 29       ; E_5
	NOTE L8, 24       ; B_4
	REST L4
	DUTY $C0
	NOTE L4, 8        ; G_3
	TIE 2
	NOTE L4, 9        ; G#3
	VIBRATO 1
	NOTE L4, 9        ; G#3
	MUS_END
Song0A_Ch3:
	BASE 35
	VOLUME $20
	NOTE L8, 5        ; E_4
	REST L8
	NOTE L8, 17       ; E_5
	REST L8
	NOTE L8, 5        ; E_4
	TRIPLET
	NOTE L8, 5        ; E_4
	TRIPLET
	NOTE L4, 17       ; E_5
	TRIPLET
	NOTE L4, 5        ; E_4
	IGNORED $01, $0F
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L8, 17       ; E_5
	VOLUME $20
	IGNORED $01, $00
	BASE 59
	NOTE L4, 11       ; A#6
	TIE 2
	NOTE L4, 12       ; B_6
	VIBRATO 1
	NOTE L4, 12       ; B_6
	MUS_END
Song0A_Vib:
	db $00, $41

;; Song $0B header: tempo, half-length flag, CH1-CH4 streams, vibrato table
Song0B:
	db $03, 1
	dw Song0B_Ch1
	dw Song0B_Ch2
	dw Song0B_Ch3
	dw $0000
	dw Song0B_Vib
Song0B_Ch1:
	BASE 35
	VOLUME $F0
	NOTE L8, 21       ; G#5
	REST L4
	NOTE L4, 2        ; C#4
	TIE 2
	NOTE L4, 3        ; D_4
	VIBRATO 1
	NOTE L4, 3        ; D_4
	MUS_END
Song0B_Ch2:
	BASE 23
	VOLUME $C0
	NOTE L8, 24       ; B_4
	REST L4
	NOTE L4, 8        ; G_3
	TIE 2
	NOTE L4, 9        ; G#3
	VIBRATO 1
	NOTE L4, 9        ; G#3
	MUS_END
Song0B_Ch3:
	BASE 35
	VOLUME $20
	TRIPLET
	NOTE L4, 5        ; E_4
	IGNORED $01, $0F
	TRIPLET
	NOTE L8, 20       ; G_5
	NOTE L8, 17       ; E_5
	VOLUME $20
	IGNORED $01, $00
	BASE 59
	NOTE L4, 11       ; A#6
	TIE 2
	NOTE L4, 12       ; B_6
	VIBRATO 1
	NOTE L4, 12       ; B_6
	MUS_END
Song0B_Vib:
	db $00, $41
Sfx01:
	SFX_CHANNELS %1010    ; CH2+CH4
	SDUTY $80
	SENV $F7
	SSLIDE -32
	SNOTE $415
	SWAIT 3
	SENV $F7
	SNOTE $008
	SNOTE $705
	SWAIT 3
	SNOTE $003
	SEND
Sfx02:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 3
	SDUTY $00
	SENV $F7
	SNOTE $739
	SWAIT 3
	SENV $F7
	SNOTE $744
	SWAIT 3
	SNOTE $74E
	SWAIT 3
	SNOTE $758
	SWAIT 3
	SENV $B7
	SNOTE $744
	SWAIT 3
	SNOTE $74E
	SWAIT 3
	SNOTE $758
	SWAIT 3
	SENV $77
	SNOTE $744
	SWAIT 3
	SNOTE $74E
	SWAIT 3
	SNOTE $758
	SWAIT 3
	SENV $37
	SNOTE $744
	SWAIT 3
	SNOTE $74E
	SWAIT 3
	SNOTE $758
	SEND
Sfx03:
	SFX_CHANNELS %0010    ; CH2
	SDUTY $80
	SENV $F7
	SNOTE $796
	SWAIT 2
	SNOTE $7FF
	SWAIT 3
	SNOTE $790
	SEND
Sfx04:
	SFX_CHANNELS %1010    ; CH2+CH4
	SWAIT 3
	SDUTY $80
	SENV $F7
	SNOTE $60B
	SWAIT 3
	SSLIDE -16
	SNOTE $744
	SWAIT 3
	SENV $B7
	SNOTE $744
	SWAIT 3
	SENV $77
	SNOTE $744
	SWAIT 3
	SENV $37
	SNOTE $744
	SEND
Sfx05:
	SFX_CHANNELS %1000    ; CH4
	SWAIT 1
	SENV $F7
	SNOTE $00C
	SWAIT 3
	SNOTE $007
	SWAIT 3
	SENV $A7
	SNOTE $007
	SWAIT 3
	SENV $57
	SNOTE $007
	SEND
Sfx06:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 1
	SDUTY $80
	SENV $F7
	SNOTE $790
	SWAIT 4
	SNOTE $758
	SWAIT 4
	SNOTE $7A2
	SWAIT 4
	SENV $67
	SNOTE $7A2
	SEND
Sfx07:
	SFX_CHANNELS %1010    ; CH2+CH4
.l5D52:
	SENV $F7
	SSLIDE 16
	SNOTE $222
	SWAIT 2
	SENV $F7
	SNOTE $00A
	SLOOP 1, .l5D52
	SNOTE $3DA
	SWAIT 5
	SNOTE $00F
	SNOTE $7FF
	SWAIT 5
	SNOTE $008
	SNOTE $7FF
	SWAIT 5
	SENV $A7
	SNOTE $008
	SNOTE $7FF
	SWAIT 5
	SENV $57
	SNOTE $008
	SEND
Sfx08:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 4
	SDUTY $C0
	SENV $F7
	SNOTE $758
	SWAIT 4
	SNOTE $79C
	SWAIT 4
	SNOTE $77B
	SWAIT 4
	SNOTE $790
	SWAIT 4
	SENV $57
	SNOTE $758
	SWAIT 4
	SNOTE $79C
	SWAIT 4
	SNOTE $77B
	SWAIT 4
	SNOTE $790
	SEND
Sfx09:
	SFX_CHANNELS %1010    ; CH2+CH4
	SDUTY $80
	SENV $F7
	SSLIDE 5
	SNOTE $7C1
	SWAIT 3
	SENV $F7
	SNOTE $004
	SENV $97
	SNOTE $7C1
	SWAIT 3
	SENV $97
	SNOTE $004
	SENV $37
	SNOTE $7C1
	SWAIT 3
	SENV $37
	SNOTE $004
.l5DCA:
	SENV $F7
	SNOTE $7DE
	SWAIT 2
	SENV $F7
	SNOTE $003
	SLOOP 5, .l5DCA
	SSLIDE 0
	SNOTE $7DE
	SWAIT 8
	SNOTE $003
	SEND
Sfx0A:
	SFX_CHANNELS %1010    ; CH2+CH4
	SENV $F7
	SNOTE $7D6
	SWAIT 2
	SENV $F7
	SNOTE $00C
	SENV $C7
	SNOTE $7BD
	SWAIT 2
	SENV $C7
	SNOTE $009
	SENV $97
	SNOTE $7BD
	SWAIT 2
	SENV $87
	SNOTE $005
	SENV $67
	SNOTE $7BD
	SWAIT 2
	SENV $67
	SNOTE $007
	SENV $F7
	SNOTE $7CE
	SWAIT 8
	SENV $F7
	SNOTE $004
	SEND
Sfx0B:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 4
	SDUTY $40
	SENV $F7
	SNOTE $77B
	SWAIT 5
	SSLIDE -48
	SNOTE $6F6
	SEND
Sfx0C:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 3
	SENV $F7
	SNOTE $790
	SWAIT 10
	SSLIDE -10
	SNOTE $000
	SEND
Sfx0D:
	SFX_CHANNELS %1000    ; CH4
	SWAIT 3
	SENV $F7
	SNOTE $008
	SWAIT 4
	SNOTE $006
	SEND
Sfx0E:
	SFX_CHANNELS %1010    ; CH2+CH4
.l5E40:
	SDUTY $80
	SENV $F7
	SSLIDE 16
	SNOTE $1C9
	SWAIT 2
	SENV $F7
	SNOTE $00D
	SNOTE $02B
	SWAIT 2
	SNOTE $00F
	SNOTE $358
	SWAIT 2
	SNOTE $00A
	SLOOP 1, .l5E40
	SNOTE $358
	SWAIT 5
	SSLIDE 1
	SNOTE $001
	SENV $C7
	SNOTE $358
	SWAIT 5
	SENV $C7
	SNOTE $001
	SENV $97
	SNOTE $358
	SWAIT 5
	SENV $97
	SNOTE $001
	SENV $67
	SNOTE $358
	SWAIT 5
	SENV $67
	SNOTE $001
	SENV $37
	SNOTE $358
	SWAIT 5
	SENV $37
	SNOTE $001
	SEND
Sfx0F:
	SFX_CHANNELS %1010    ; CH2+CH4
	SDUTY $80
	SENV $F7
	SNOTE $02B
	SWAIT 4
	SENV $F7
	SNOTE $008
	SSLIDE -16
	SNOTE $705
	SWAIT 4
	SNOTE $006
	SENV $B7
	SNOTE $705
	SWAIT 4
	SENV $B7
	SNOTE $006
	SENV $77
	SNOTE $705
	SWAIT 4
	SENV $77
	SNOTE $006
	SENV $37
	SNOTE $705
	SWAIT 4
	SENV $37
	SNOTE $006
	SEND
Sfx11:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 5
	SDUTY $C0
	SENV $F7
	SSLIDE -5
	SNOTE $705
	SWAIT 16
	SSLIDE -10
	SVIBRATO $40
	SREPEAT $8F, $FF
	SEND
Sfx12:
	SFX_CHANNELS %1010    ; CH2+CH4
	SDUTY $00
	SENV $A7
	SVIBRATO $60
	SNOTE $222
	SENV $F7
	SVIBRATO $A0
	SNOTE $00C
	SEND
Sfx13:
	SFX_CHANNELS %1010    ; CH2+CH4
	SENV $F7
	SNOTE $358
	SWAIT 2
	SENV $F7
	SNOTE $00E
	SENV $C7
	SNOTE $3DA
	SWAIT 2
	SENV $C7
	SNOTE $003
	SENV $97
	SNOTE $106
	SWAIT 2
	SENV $97
	SNOTE $008
	SENV $67
	SNOTE $277
	SWAIT 2
	SENV $67
	SNOTE $00D
	SENV $37
	SNOTE $415
	SWAIT 2
	SENV $37
	SNOTE $002
	SNOTE $7FF
	SWAIT 2
	SNOTE $007
	SENV $37
	SNOTE $2C9
	SWAIT 2
	SENV $37
	SNOTE $00F
	SENV $67
	SNOTE $44E
	SWAIT 2
	SENV $67
	SNOTE $00E
	SENV $97
	SNOTE $222
	SWAIT 2
	SENV $97
	SNOTE $005
	SENV $C7
	SNOTE $16A
	SWAIT 2
	SENV $C7
	SNOTE $001
	SEND
Sfx14:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 8
	SVIBRATO $E0
	SENV $F7
	SSLIDE -3
	SNOTE $705
	SWAIT 8
	SSLIDE -6
	SNOTE $000
	SEND
Sfx15:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 2
	SENV $F7
	SNOTE $688
	SEND
Sfx16:
	SFX_CHANNELS %1000    ; CH4
	SWAIT 6
	SENV $F7
	SSLIDE -1
	SNOTE $006
	SEND
Sfx17:
	SFX_CHANNELS %1010    ; CH2+CH4
	SENV $F7
	SSLIDE -8
	SVIBRATO $E0
	SNOTE $222
	SWAIT 159
	SENV $87
	SVIBRATO $00
	SNOTE $007
	SEND
Sfx18:
	SFX_CHANNELS %0010    ; CH2
	SENV $F7
	SNOTE $744
	SEND
Sfx19:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 3
	SDUTY $80
	SENV $F7
	SNOTE $7A2
	SWAIT 3
	SENV $87
	SNOTE $7A2
	SWAIT 4
	SENV $F7
	SNOTE $790
	SWAIT 4
	SENV $A7
	SNOTE $790
	SWAIT 4
	SENV $57
	SNOTE $790
	SEND
Sfx1A:
	SFX_CHANNELS %1010    ; CH2+CH4
	SDUTY $40
	SENV $F7
	SVIBRATO $A0
	SSLIDE 1
	SNOTE $7BD
	SWAIT 96
	SEND
Sfx1B:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 5
	SDUTY $C0
	SVIBRATO $E0
	SENV $F7
	SSLIDE -9
	SNOTE $758
	SWAIT 4
	SSLIDE -6
	SNOTE $758
	SSLIDE -3
	SNOTE $758
	SWAIT 4
	SSLIDE 0
	SNOTE $758
	SWAIT 4
	SSLIDE 3
	SNOTE $758
	SWAIT 4
	SSLIDE 6
	SNOTE $758
	SWAIT 4
	SSLIDE 9
	SNOTE $758
	SWAIT 4
	SSLIDE 12
	SNOTE $758
	SWAIT 4
	SSLIDE 15
	SNOTE $758
	SWAIT 4
	SSLIDE 18
	SNOTE $758
	SWAIT 4
	SSLIDE 21
	SNOTE $758
	SEND
Sfx20:
	SFX_CHANNELS %0010    ; CH2
	SWAIT 4
	SDUTY $80
	SENV $F7
	SNOTE $7C1
	SWAIT 4
	SENV $97
	SNOTE $7C1
	SWAIT 4
	SENV $37
	SNOTE $7C1
	SWAIT 4
	SENV $F7
	SNOTE $7B1
	SWAIT 4
	SENV $97
	SNOTE $7B1
	SWAIT 4
	SENV $37
	SNOTE $7B1
	SEND
Sfx21:
	SFX_CHANNELS %1111    ; CH1+CH2+CH3+CH4
.l6026:
	SENV $F7
	SNOTE $672
	SENV $F7
	SNOTE $6B1
	SNOTE $60B
	SWAIT 12
	SNOTE $004
	SLOOP 1, .l6026
	SNOTE $672
	SNOTE $6B1
	SNOTE $60B
	SWAIT 6
	SNOTE $004
	SDUTY $80
	SNOTE $7CE
	SDUTY $80
	SNOTE $7D6
	SNOTE $60B
	SWAIT 6
	SNOTE $004
	SENV $A7
	SNOTE $7CE
	SENV $A7
	SNOTE $7D6
	SNOTE $60B
	SWAIT 6
	SNOTE $004
	SENV $57
	SNOTE $7CE
	SENV $57
	SNOTE $7D6
	SNOTE $60B
	SWAIT 6
	SNOTE $004
	SDUTY $00
	SENV $F7
	SNOTE $69D
	SDUTY $00
	SENV $F7
	SNOTE $6D6
	SNOTE $641
	SWAIT 12
	SNOTE $004
	SNOTE $69D
	SNOTE $6D6
	SNOTE $641
	SWAIT 6
	SNOTE $004
	SNOTE $69D
	SNOTE $6D6
	SNOTE $641
	SWAIT 12
	SNOTE $004
	SNOTE $69D
	SNOTE $6D6
	SNOTE $641
	SWAIT 6
	SNOTE $004
	SDUTY $80
	SNOTE $7D3
	SDUTY $80
	SNOTE $7DA
	SNOTE $641
	SWAIT 6
	SNOTE $004
	SENV $A7
	SNOTE $7D3
	SENV $A7
	SNOTE $7DA
	SNOTE $641
	SWAIT 6
	SENV $57
	SNOTE $004
	SENV $57
	SNOTE $7D3
	SENV $57
	SNOTE $7DA
	SNOTE $641
	SWAIT 6
	SNOTE $004
	SDUTY $C0
	SENV $F7
	SNOTE $76B
	SDUTY $C0
	SENV $F7
	SNOTE $790
	SNOTE $744
	SWAIT 18
	SNOTE $004
	SNOTE $76B
	SNOTE $782
	SNOTE $744
	SWAIT 18
	SNOTE $004
	SNOTE $77B
	SNOTE $790
	SNOTE $758
	SWAIT 18
	SNOTE $004
	SNOTE $789
	SNOTE $79C
	SNOTE $76B
	SWAIT 18
	SWAIT 20
	SEND

SECTION "DT Sound glue bank 2", ROMX[$615F], BANK[2]


;; Song request per stage (hSndRequest values), indexed by wStage
StageMusicTable:
	db $41, $42, $43, $44, $45, $42

;; SndPlayStageMusic: request the stage song, unless music is playing.
SndPlayStageMusic:
	ldh a, [hMusicID]
	and a, a
	ret nz
	ld hl, StageMusicTable
	ld a, [wStage]
	rst $20
	ldh [hSndRequest], a
	ret

;; SndRequest: B = request. An SFX request does not replace a pending SFX
;; request of higher priority; a song request is ignored if that song is playing.
SndRequest:
	ld hl, SfxPriority
	ld a, b
	cp a, $40
	jr nc, .song
	rst $20
	ld c, a
	ldh a, [hSndRequest]
	and a, a
	jr z, .set
	cp a, $40
	ret nc
	ld hl, SfxPriority
	rst $20
	cp a, c
	ret nc
.set:
	ld a, b
	ldh [hSndRequest], a
	ret
.song:
	and a, $3F
	ld c, a
	ldh a, [hMusicID]
	cp a, c
	jr nz, .set
	ret
