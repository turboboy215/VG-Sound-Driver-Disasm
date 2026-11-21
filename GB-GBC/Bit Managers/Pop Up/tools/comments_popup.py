# executed inside gen_popup.py (g = Gen)
B = g.blocks
C = g.comments

B[0x50A0] = '''22 bytes that nothing references (not used by the game or the driver).'''
B[0x50B6] = '''PlaySound while hSfxLock is set: the request is dropped.
BUG: clears byte $39 of page h, and h is whatever the caller had in h
(from the game this writes to an arbitrary RAM page).'''
B[0x50BC] = '''PlaySoundChecked (a = id): skip if hSfxAtten = $0F, else PlaySoundLock.
Not called by the game.'''
B[0x50D1] = '''PlaySoundLock: stop the current SFX, start sound a, and set hSfxLock so that
later PlaySound calls are ignored until this SFX ends. Only reached from
PlaySoundChecked.'''
B[0x50E4] = '''PlaySound (a = sound id 1-7): public entry, keeps bc/de/hl.
Stops a running SFX, saves hMask, starts the stream on the SFX page ($C4xx)
and parses its first tick immediately (inside the call).'''
B[0x510D] = '''Sound table lookup: SfxTable_m2 + 2*id. Only [$C402/3] (stream pointer) is set,
not the order-list pointer, and the rest of the SFX page keeps its old state.'''
B[0x511F] = '''Timer interrupt (TMA=$B4, TAC=4: 4096/76 = 53.89 Hz). Runs SndUpdate only while
the LCD is off (hLCDOff = 0) and hSndOn != 0. With the LCD on the VBlank
handler calls SndUpdate instead (59.73 Hz).'''
B[0x5135] = '''SndUpdate: one driver tick. NR50 = $FF and NR52 = $8F every tick.
Ticks the four pages (Ch1, Ch2, Ch3, Sfx), then (if hSndOn) writes the
dead registers 6/7 and outputs Ch2, Ch3 and either Sfx (while wSfxId != 0) or Ch1 to CH1.'''
B[0x5169] = '''OutputChannel (h = page): write freq lo/hi and volume through WriteReg using
the register indices in fields $06/$08/$0A. Volume = (vol - vol table) (or
field $37 if nonzero), minus field $38, minus hSfxAtten (Sfx page while
wSfxLockedVol = 0) or hMusAtten (others). Advances h.'''
B[0x51D2] = '''StopAll: hSndOn = 0, reset all four pages, hTranspose = 0, unlock SFX,
NR51 = 0. Also the game's sound init and the STOP_ALL command.'''
B[0x5243] = '''ChannelTick (h = page): skipped while field $30 = 0.'''
B[0x5299] = '''ReadStream (de = stream): process bytes until a note or a "wait"
command ends the tick. hInInstr = $C9 while an instrument macro runs (then
nothing here may run; the ret z is never taken in practice).'''
B[0x5327] = '''Command ranges: $DF+ length, $CF+ vol/env, $BF+ volume, $B0+ arpeggio,
$9A+ play SFX, $80+ instrument, $60-$7F table.'''
B[0x5440] = '''DoArp: add the next arpeggio table entry to the note. $73 restarts the table,
$FF holds (field $2E = 1, offset 0).'''
B[0x546B] = '''SetNoteFreq (a = note): index = note - 12 (- 36 more on Ch3) + hTranspose
(the SFX page subtracts hTranspose again) -> PeriodTable. With BEND active
the start offset (fields $27/$28) is added and the slide count restarts.'''
B[0x5558] = '''Cmd_Instrument ($80-$99): runs the instrument macro (commands only, no
notes) until $70 or $73. Instruments 2 and 3 ($82/$83) also fire a noise hit.'''
B[0x55CD] = '''Cmd_NoteOff ($77): save the vol-table pointer/flag, point it to
NoteOffVolTable (decay), and wait. The next note restores it.'''
B[0x5623] = '''Cmd_PlaySfx ($9A-$AF): start sound (byte - $9A) on the SFX page, mark this
channel (field $39) so that its next note stops the SFX again, then wait.'''
B[0x5725] = '''ApplyVolTable: if field $34 is set, read the next byte of the volume table
(fields $31/$32, index $33): $FF holds, $73 restarts. Returns vol - entry
(floor 0) in a.'''
B[0x5751] = '''DoEnvelope: attack (fields $0F/$10/$19/$1A), then decay ($12/$13/$1B/$1C),
then release ($18 set by CheckRelease: $17/$1D/$1E).'''
B[0x57AD] = '''Period table: 70 entries, C2 (65.4 Hz) .. A7. The last entries are not monotonic
($07E6 is followed by $07E2).'''
B[0x584F] = '''StartMusicChN (de = order list): reset the page, set field $30, read the first
pattern pointer and store the order position.'''
B[0x587C] = '''Cmd_Next ($73): next pattern from the order list. A 0 word ends the list; the
next word is the new order position (executed as ORDER_JUMP).'''
B[0x58CB] = '''WriteReg (a = index 0-12, c = value): through RegHandlerTable; indices >= 13 are ignored.
Freq-hi and volume writes are skipped when the shadow already holds the value;
when they do happen they retrigger the channel.'''
B[0x5999] = '''Save IE and disable all interrupts / restore IE (used while starting the title music).'''
B[0x59A6] = '''PlayTitleMusic: called by the game (title screen).'''
B[0x5E43] = '''PlaySong2: called by the game.'''
B[0x5EC2] = '''Instrument table: entry n+1 for instrument n (the first word belongs to nothing).'''
B[0x5FAE] = '''Arpeggio table: 15 pointers. Only 0-2 point to arpeggio data; 3-14 point into
SfxTable_m2 (garbage, not used by the songs).'''
B[0x5FD3] = '''Sound table: entry id for sound id (id 0 would read the word $7304).'''

C.update({
    0x524C: 'jr z, +0: dead test of flag bit 4',
    0x5299: 'nop',
    0x5356: 'call the handler at bc',
    0x52E1: 'hCh1NoteFlag = 1 on every Ch1 note (read by the game)',
    0x5195: 'field $2F is never set: dead',
})

B[0x5EC4] = '''Instrument table: instrument n = entry n (code reads InstrTable - 2 + 2*(byte - $7F)).'''
B[0x5FD5] = '''Sound table: ids 1-7 (code reads SfxTable - 2 + 2*id; id 0 would read the word $7304).'''
B.pop(0x5EC2, None); B.pop(0x5FD3, None)
B[0x55CB] = '''Dead bytes (sub $9A), not reachable.'''
B[0x560C] = '''Dead handler, not in CmdTable: pop af / res 4,[field $04] / ret.'''
B[0x5DB1] = '''Pattern that no order list uses.'''
O = g.operand
O.update({
    0x510E: 'LOW(SfxTable - 2)', 0x5111: 'HIGH(SfxTable - 2)',
    0x534A: 'LOW(CmdTable)', 0x534D: 'HIGH(CmdTable)',
    0x55B4: 'LOW(CmdTable)', 0x55B7: 'HIGH(CmdTable)',
    0x5391: 'LOW(ArpTable)', 0x5394: 'HIGH(ArpTable)',
    0x548C: 'LOW(PeriodTable)', 0x548F: 'HIGH(PeriodTable)',
    0x58D5: 'LOW(RegHandlerTable)', 0x58D8: 'HIGH(RegHandlerTable)',
    0x5579: 'InstrTable - 2',
    0x596F: 'LOW(Ch3VolTable)', 0x5972: 'HIGH(Ch3VolTable)',
    0x55DA: 'LOW(NoteOffVolTable)', 0x55DD: 'HIGH(NoteOffVolTable)',
})

for _k in list(O):
    if _k not in g.code and (_k - 1) in g.code:
        O[_k - 1] = O.pop(_k)
    elif _k not in g.code:
        print('operand override not on an instruction:', hex(_k))
