; Xantera sound engine (4x4 World Trophy) - RAM, macros, constants
;
; Song events are time-stamped: every event starts with the absolute song
; time (frames since the song started) as a big-endian word, then a command
; byte whose high nibble is the event type and low nibble the channel or
; argument.

IF !DEF(XANTERA_SOUND_INC)
DEF XANTERA_SOUND_INC EQU 1

; ---- RAM -------------------------------------------------------------------
DEF wXMusPlaying     EQU $C37B  ; nonzero while a song is running
DEF wXMusTime        EQU $C37C  ; song clock in frames, big-endian (hi, lo)
DEF wXMusPtr         EQU $C37E  ; next event, big-endian
DEF wXQueuedPtr      EQU $C380  ; song queued by XSnd_QueueSong, big-endian
DEF wXQueuedBank     EQU $C382
DEF wXSndFlags       EQU $C383  ; bits 0-3 SFX owns ch1-4, bit 4 engine on, bit 7 song queued
DEF wXSfxTimer1      EQU $C384  ; SFX repeat timers ch1, ch2, ch3, ch4
DEF wXSfxTimer2      EQU $C385
DEF wXSfxTimer3      EQU $C386
DEF wXSfxTimer4      EQU $C387
DEF wXSfxPtr1        EQU $C388  ; SFX record pointers ch1-4, big-endian (set by the game)
DEF wXSfxPtr2        EQU $C38A  ; never written by the game
DEF wXSfxPtr3        EQU $C38C
DEF wXSfxPtr4        EQU $C38E
DEF wXWaveCur        EQU $C390  ; wave last loaded by XSnd_LoadWave, big-endian
DEF wXWaveSave       EQU $C392  ; music wave to restore after a ch3 SFX, big-endian
DEF wXMusBank        EQU $C394  ; ROM bank of the song
DEF wXSavedBank      EQU $C396  ; game bank saved during XSnd_Update
DEF wXEngineRpm      EQU $C398  ; engine pitch input (written by the game)
DEF wXEngineRpmLast  EQU $C399
DEF wXCurBank        EQU $C39A  ; game's shadow of the mapped ROM bank

; wXSndFlags bits
DEF XSNDB_SFX1   EQU 0   ; SFX owns ch1 (music notes skipped)
DEF XSNDB_SFX2   EQU 1
DEF XSNDB_SFX3   EQU 2
DEF XSNDB_SFX4   EQU 3
DEF XSNDB_ENGINE EQU 4   ; engine voice owns ch3
DEF XSNDB_QUEUED EQU 7   ; wXQueuedPtr/Bank hold a song to start

; ---- helpers ---------------------------------------------------------------
MACRO bigw   ; big-endian word
    REPT _NARG
        db HIGH(\1), LOW(\1)
        SHIFT
    ENDR
ENDM

; ---- song events -----------------------------------------------------------
; time = absolute frame count from song start (0-65535)

MACRO _ev    ; time, command
    db HIGH(\1), LOW(\1), \2
ENDM

; $10 / $11: pulse note. env = NRx2. Byte 2 is NRx1|$80 and NRx4 bits 0-2,
; so the duty is always 50% unless bit 6 is set (never used).
MACRO ch1_note   ; time, env, period
    _ev \1, $10
    db \2, HIGH(\3), LOW(\3)
ENDM
MACRO ch2_note   ; time, env, period
    _ev \1, $11
    db \2, HIGH(\3), LOW(\3)
ENDM
; $12: wave note. vol = NR32 value ($20 100%, $40 50%, $60 25%)
MACRO ch3_note   ; time, vol, period
    _ev \1, $12
    db (\2) | HIGH(\3), LOW(\3)
ENDM
; $13: noise note. vol = NR42 high nibble, inst = XNoiseTable index
MACRO ch4_note   ; time, vol, inst
    _ev \1, $13
    db ((\2) << 4) | (\3)
ENDM
; $2x: ch3 off (NR30 = 0). Low nibble ignored; the data always uses $22.
MACRO ch3_off    ; time
    _ev \1, $22
ENDM
; $3n: NR32 = n << 4 (unused in the data)
MACRO ch3_vol    ; time, n
    _ev \1, $30 | (\2)
ENDM
; $4n: load wave n (16 bytes from XWaveTable + n*16)
MACRO wave       ; time, n
    _ev \1, $40 | (\2)
ENDM
; $5c: new period for channel c (0-2) without retrigger (unused in the data)
MACRO pitch      ; time, channel, period
    _ev \1, $50 | (\2)
    db LOW(\3), HIGH(\3)
ENDM
; any other command ends the song; the data uses $60
MACRO song_end   ; time
    _ev \1, $60
ENDM

; ---- instrument / SFX records ----------------------------------------------
MACRO noise_inst ; NR41, NR42 low nibble, NR43, NR44
    db \1, \2, \3, \4
ENDM
; first byte = repeat timer: 0/1 one-shot, n>1 retrigger every n-1 frames
MACRO sfx1  ; timer, NR10, NR11, NR12, NR13, NR14
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx2  ; timer, NR21, NR22, NR23, NR24
    db \1, \2, \3, \4, \5
ENDM
MACRO sfx3  ; timer, NR30, NR31, NR32, NR33, NR34
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx4  ; timer, NR41, NR42, NR43, NR44
    db \1, \2, \3, \4, \5
ENDM

; ---- note periods ----------------------------------------------------------
; The driver has no frequency table: songs store raw 11-bit periods. These
; are the values the data uses (one per note; C_2 = MIDI 36). Names give the
; pulse-channel pitch: the same period on ch3 sounds one octave lower.
DEF C_2 EQU   44
DEF Cs2 EQU  156
DEF Ds2 EQU  362
DEF F_2 EQU  546
DEF Fs2 EQU  630
DEF G_2 EQU  710
DEF Gs2 EQU  785
DEF A_2 EQU  856
DEF As2 EQU  923
DEF C_3 EQU 1045
DEF Cs3 EQU 1102
DEF D_3 EQU 1155
DEF Ds3 EQU 1205
DEF E_3 EQU 1252
DEF F_3 EQU 1297
DEF Fs3 EQU 1339
DEF G_3 EQU 1379
DEF Gs3 EQU 1416
DEF A_3 EQU 1452
DEF As3 EQU 1485
DEF C_4 EQU 1547
DEF Cs4 EQU 1575
DEF D_4 EQU 1601
DEF Ds4 EQU 1626
DEF E_4 EQU 1650
DEF F_4 EQU 1672
DEF Fs4 EQU 1693
DEF G_4 EQU 1713
DEF Gs4 EQU 1732
DEF A_4 EQU 1750
DEF As4 EQU 1766
DEF C_5 EQU 1797
DEF Cs5 EQU 1811
DEF D_5 EQU 1824
DEF Ds5 EQU 1837
DEF E_5 EQU 1849
DEF F_5 EQU 1860
DEF Fs5 EQU 1870
DEF G_5 EQU 1880
DEF Gs5 EQU 1890
DEF A_5 EQU 1899
DEF As5 EQU 1907
DEF B_5 EQU 1915
DEF C_6 EQU 1922
DEF Cs6 EQU 1929
DEF D_6 EQU 1936
DEF Ds6 EQU 1942
DEF E_6 EQU 1948
DEF F_6 EQU 1954
DEF G_6 EQU 1964
DEF Gs6 EQU 1969
DEF As6 EQU 1977

ENDC
