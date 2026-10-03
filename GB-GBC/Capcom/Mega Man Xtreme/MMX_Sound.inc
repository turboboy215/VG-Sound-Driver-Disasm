; =============================================================================
; Mega Man Xtreme (GBC, USA) - sound driver definitions
; ROM: "Megaman Xtreme (U) [C][!].gbc", MBC5, 1 MB
; =============================================================================

IF !DEF(MMX_SOUND_INC)
DEF MMX_SOUND_INC EQU 1

; ---- hardware
DEF rROMB0           EQU $2000
DEF rNR10            EQU $FF10
DEF rNR11            EQU $FF11
DEF rNR12            EQU $FF12
DEF rNR13            EQU $FF13
DEF rNR14            EQU $FF14
DEF rNR21            EQU $FF16
DEF rNR22            EQU $FF17
DEF rNR23            EQU $FF18
DEF rNR24            EQU $FF19
DEF rNR30            EQU $FF1A
DEF rNR31            EQU $FF1B
DEF rNR32            EQU $FF1C
DEF rNR33            EQU $FF1D
DEF rNR34            EQU $FF1E
DEF rNR41            EQU $FF20
DEF rNR42            EQU $FF21
DEF rNR43            EQU $FF22
DEF rNR44            EQU $FF23
DEF rNR50            EQU $FF24
DEF rNR51            EQU $FF25
DEF rNR52            EQU $FF26
DEF _AUD3WAVERAM     EQU $FF30

; ---- WRAM ($CD00-$CDC9)
DEF wSndFlags          EQU $CD00        ; b0 busy (API call) / new SFX segment, b1 APU set up, b2 SFX pass, b3 music paused, b7 SFX loops
DEF wSndChanReg        EQU $CD01        ; current channel: register offset from NR10 (0, 5, 10, 15)
DEF wSndInstPtr        EQU $CD02        ; [2] pointer to the current channel's instrument (8 bytes)
DEF wMusicPan          EQU $CD04        ; NR51 image of the music (rotated one channel per pass)
DEF wMusChanOfs        EQU $CD05        ; offset of the current music channel struct from wSfxChannel
DEF wTempo             EQU $CD06        ; [2] ticks per frame, 8.8 fixed point (lo, hi). Default $0199
DEF wTempoFrac         EQU $CD08        ; tempo accumulator
DEF wTicks             EQU $CD09        ; ticks to count off this frame
DEF wSfxPan            EQU $CD0A        ; NR51 image of the SFX (rotated like wMusicPan)
DEF wGlobalTranspose   EQU $CD0B        ; GTRANSP
DEF wMusWaveInstr      EQU $CD0C        ; instrument whose wave CH3 music uses
DEF wFadeCmd           EQU $CD0D        ; command index of the running fade (5/6), 0 = none
DEF wFadeSpeed         EQU $CD0E        ; bits 6-0 speed, bit 7 = fade out
DEF wFadeLevel         EQU $CD0F        ; [2] fade level (hi, lo)
DEF wSfxChannels       EQU $CD11        ; channels used by the SFX (bits 0-3; rotated during the update)
DEF wSfxPriority       EQU $CD12        ; priority of the SFX playing (0 = none)
DEF wSfxPtr            EQU $CD13        ; [2] SFX stream pointer (lo, hi)
DEF wSfxLoopID         EQU $CD15        ; id+1 of a looping SFX to resume after a higher-priority SFX
DEF wSfxPitch          EQU $CD16        ; pitch offset for looping SFX (command $F7)
DEF wSfxFrames         EQU $CD17        ; frames left in the SFX segment
DEF wSfxHold           EQU $CD18        ; segment key-off point (x/256 of the duration)
DEF wSfxHoldTimer      EQU $CD19        ; frames until key-off (CH1/2/4)
DEF wSfxWaveHold       EQU $CD1A        ; CH3 key-off point
DEF wSfxWaveHoldTimer  EQU $CD1B        ; frames until CH3 key-off
DEF wSfxTranspose      EQU $CD1C        ; segment transpose
DEF wSfxLoopCount      EQU $CD1D        ; segment loop counter
DEF wSfxChannel        EQU $CD1E        ; [64] 4 x $10-byte channel state for the SFX
DEF wMusChannel        EQU $CD5E        ; [108] 4 x $1B-byte channel state for the music

; ---- game variables used by the glue
DEF hSndID             EQU $FFF7        ; game: sound id for GamePlaySound
DEF hSndBank           EQU $FFF8        ; game: sound bank (2, 3 or 4)
DEF BankNumber         EQU $7FFE        ; every ROM bank stores its number here

; ---- channel state (SFX: $10 bytes, music: $1B bytes)
DEF CHN_INSTR          EQU $00          ; instrument + 1 (0 = none)
DEF CHN_STATE          EQU $01          ; b0 silent (rest/key-off), b4 instrument changed, b5 slide active, b6 vibrato half, b7 slide up
DEF CHN_VIBPHASE       EQU $02          ; vibrato phase (b7-6 quadrant, b5-0 position)
DEF CHN_ENVPHASE       EQU $03          ; 0 off, 1 attack, 2 decay, 3 sustain, 4 release
DEF CHN_ENVRATE        EQU $04          ; frames per hardware envelope step (reload)
DEF CHN_ENVTIMER       EQU $05          ; frames to the next step
DEF CHN_ENVLEVEL       EQU $06          ; software copy of the hardware envelope volume
DEF CHN_VOLUME         EQU $07          ; VOLUME (CH3: NR32 value)
DEF CHN_DETUNE         EQU $08          ; DETUNE (signed, added to the period)
DEF CHN_SLIDE          EQU $09          ; SLIDE speed, b7 = direction
DEF CHN_SLIDENOTE      EQU $0A          ; previous note (slide source)
DEF CHN_PITCH          EQU $0B          ; current pitch (PitchTable units, lo)
DEF CHN_PITCH_HI       EQU $0C          
DEF CHN_FREQ           EQU $0D          ; period written to NRx3/NRx4 (lo)
DEF CHN_FREQ_HI        EQU $0E          
DEF CHN_DUTY           EQU $0F          ; NRx1 (CH4: NR43 low bits)
DEF CHN_PTR            EQU $10          ; music stream pointer (lo) - music only from here
DEF CHN_PTR_HI         EQU $11          
DEF CHN_FLAGS          EQU $12          ; b7 connect (this note), b6 CONNECT, b5 TRIPLET, b4 DOTTED, b3 OCTUP, b2-0 OCTAVE
DEF CHN_TRANSP         EQU $13          ; TRANSP
DEF CHN_LENGTH         EQU $14          ; ticks left in the note
DEF CHN_HOLD           EQU $15          ; HOLD (key-off point, x/256)
DEF CHN_KEYOFF         EQU $16          ; ticks until key-off
DEF CHN_LOOP1          EQU $17          ; counter for LOOP1/LOOP3/LOOP4 and their BREAKs
DEF CHN_LOOP2          EQU $18          ; counter for LOOP2/BREAK2
DEF SFXCHN_SIZE EQU $10
DEF MUSCHN_SIZE EQU $1B
DEF NUM_SOUND_IDS EQU $7E


; =============================================================================
; Music stream (Capcom NES "6C80" engine format, GB variant)
DEF N64 EQU 1   ; 3 ticks
DEF N32 EQU 2   ; 6
DEF N16 EQU 3   ; 12
DEF N8  EQU 4   ; 24
DEF N4  EQU 5   ; 48
DEF N2  EQU 6   ; 96
DEF N1  EQU 7   ; 192
MACRO NOTE      ; length, pitch 1-31 (1 = C at octave 0 = C2)
	db ((\1) << 5) | (\2)
ENDM
MACRO REST
	db (\1) << 5
ENDM
MACRO TRIPLET   ; toggle triplet lengths
	db $00
ENDM
MACRO CONNECT   ; toggle: connected notes are not retriggered
	db $01
ENDM
MACRO DOTTED    ; next note 1.5x
	db $02
ENDM
MACRO OCTUP     ; toggle +2 octaves
	db $03
ENDM
MACRO FLAGS     ; set CHN_FLAGS bits 6-5, 3-0
	db $04, \1
ENDM
MACRO TEMPO     ; 8.8 ticks per frame
	db $05, HIGH(\1), LOW(\1)
ENDM
MACRO HOLD      ; key-off point, x/256 of the note
	db $06, \1
ENDM
MACRO VOLUME
	db $07, \1
ENDM
MACRO INSTR
	db $08, \1
ENDM
MACRO OCTAVE
	db $09, \1
ENDM
MACRO GTRANSP
	db $0A, LOW(\1)
ENDM
MACRO TRANSP
	db $0B, LOW(\1)
ENDM
MACRO DETUNE
	db $0C, LOW(\1)
ENDM
MACRO SLIDE
	db $0D, \1
ENDM
MACRO LOOP1     ; count, label
	db $0E, \1, HIGH(\2), LOW(\2)
ENDM
MACRO LOOP2
	db $0F, \1, HIGH(\2), LOW(\2)
ENDM
MACRO LOOP3
	db $10, \1, HIGH(\2), LOW(\2)
ENDM
MACRO LOOP4
	db $11, \1, HIGH(\2), LOW(\2)
ENDM
MACRO BREAK1    ; flags, label
	db $12, \1, HIGH(\2), LOW(\2)
ENDM
MACRO BREAK2
	db $13, \1, HIGH(\2), LOW(\2)
ENDM
MACRO BREAK3
	db $14, \1, HIGH(\2), LOW(\2)
ENDM
MACRO BREAK4
	db $15, \1, HIGH(\2), LOW(\2)
ENDM
MACRO JUMP
	db $16, HIGH(\1), LOW(\1)
ENDM
MACRO END
	db $17
ENDM
MACRO DUTY      ; NRx1 (CH4: NR43 bits)
	db $18, \1
ENDM
MACRO PAN       ; NR51 bits for the channel: $11 both, $10 left, $01 right
	db $19, \1
ENDM
MACRO BEPTR
	db HIGH(\1), LOW(\1)
ENDM

; =============================================================================
; SFX (segments)
MACRO SFX_PRIORITY  ; priority 1-127, loop flag
	db (\1) | ((\2) << 7)
ENDM
MACRO SEGMENT   ; NR51 bits (nonzero), flags (b0 loop, b1 hold, b2 transpose)
	db \1, \2
ENDM
MACRO SEG_LOOP  ; count (0 = forever), label
	db \1, HIGH(\2), LOW(\2)
ENDM
MACRO SEG_HOLD
	db \1
ENDM
MACRO SEG_TRANSP
	db LOW(\1)
ENDM
MACRO SEG_FRAMES    ; duration, channel mask
	db \1, \2
ENDM
MACRO SFX_END
	db $00
ENDM
; Per channel: flags (b0 instr, b1 duty, b2 volume, b3 slide, b4 detune),
; one byte per flag, then the note (0 = key off, $FF = hold). Written as db.

MACRO INSTRUMENT    ; attack, decay, sustain, release, vib speed, vib depth, duty, wave
	db \1, \2, \3, \4, \5, \6, \7, \8
ENDM

ENDC
