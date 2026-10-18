"""Shared pieces for the HAL generators: macro file text, a12-idiom hints, file writing."""
import os, re

MACROS_KDL = r'''; HAL Laboratory GB sound engine - data macros (KDL command set)

; ---- track header ----
DEF CH1 EQU $00   ; register offset / 4 selects NR1x
DEF CH2 EQU $04
DEF CH4 EQU $0C
DEF CH3 EQU $10

MACRO track ; pointer, channel
	dw \1
	db \2
ENDM

; ---- main stream ----
; note offset, len    offset -15..15 from the base note, len = index 0-5 into the length set
MACRO note
	ASSERT (\2) >= 0 && (\2) < 6
	ASSERT (\1) >= -15 && (\1) <= 15
	db ((\2) << 5) | ((\1) & $1F)
ENDM
MACRO note_x ; offset, frames
	db $C0 | ((\1) & $1F), \2
ENDM
MACRO rest ; len index
	db ((\1) << 5) | $10
ENDM
MACRO rest_x ; frames
	db $D0, \1
ENDM
; noise track: drum n (0-14 = NoiseTable entry; +16 = trigger without a new NR43), $0F = rest
MACRO drum
	ASSERT (\2) >= 0 && (\2) < 6
	db ((\2) << 5) | (\1)
ENDM
MACRO drum_x
	db $C0 | (\1), \2
ENDM
MACRO drest
	db ((\1) << 5) | $0F
ENDM
MACRO drest_x
	db $CF, \1
ENDM

MACRO sync          ; game-visible marker (wSoundSync)
	db $E1, \1
ENDM
MACRO frequency     ; set the period directly and restart the envelope
	db $E2
	dw \1
ENDM
MACRO detune        ; period -= n (signed): positive lowers the pitch
	db $E3, \1
ENDM
MACRO volume        ; channel volume 0-15
	db $F0, \1
ENDM
MACRO volume_add    ; channel volume += n (clamped)
	db $F1, \1
ENDM
MACRO length_set    ; select length set n (6 entries each)
	db $F2, \1
ENDM
MACRO hold          ; wait n frames, no new note
	db $F3, \1
ENDM
MACRO gate          ; release after len*n/256 frames (0 = never)
	db $F4, \1
ENDM
MACRO base_note
	db $F5, \1
ENDM
DEF STATIC EQU $80
MACRO instrument    ; n [, STATIC]: STATIC runs the envelope once now instead of per note
	IF _NARG == 2
		db $F6, (\1) | (\2)
	ELSE
		db $F6, \1
	ENDC
ENDM
MACRO tuning
	db $F7, \1
ENDM
MACRO snd_jump
	db $F8
	dw \1
ENDM
MACRO snd_call
	db $FA
	dw \1
ENDM
MACRO snd_ret
	db $FB
ENDM
MACRO snd_loop      ; count
	db $FC, \1
ENDM
MACRO snd_endloop
	db $FD
ENDM
DEF PAN_OFF EQU 0
DEF PAN_L   EQU 1   ; bit 0: left output (NR51 bits 4-7)
DEF PAN_R   EQU 2   ; bit 1: right output (NR51 bits 0-3)
DEF PAN_LR  EQU 3
MACRO pan
	db $FE, \1
ENDM
MACRO snd_end
	db $FF
ENDM

; ---- envelope (instrument macro) stream ----
DEF WAIT EQU $10    ; optional 2nd argument: wait 1 frame after this step
MACRO env_wait
	ASSERT (\1) < 32
	db \1
ENDM
MACRO env_pitch
	IF _NARG == 2
		db $20 | ((\1) & $0F) | (\2)
	ELSE
		db $20 | ((\1) & $0F)
	ENDC
ENDM
MACRO env_vol
	IF _NARG == 2
		db $40 | (\1) | (\2)
	ELSE
		db $40 | (\1)
	ENDC
ENDM
MACRO env_vol_add
	IF _NARG == 2
		db $60 | ((\1) & $0F) | (\2)
	ELSE
		db $60 | ((\1) & $0F)
	ENDC
ENDM
MACRO env_timbre    ; duty 0-3 (ch1/2/4) or wave number (ch3)
	IF _NARG == 2
		db $80 | (\1) | (\2)
	ELSE
		db $80 | (\1)
	ENDC
ENDM
MACRO env_reg0      ; NR10 (sweep) / NR30
	db $F0, \1
ENDM
MACRO env_jump
	db $F8
	dw \1
ENDM
MACRO env_call
	db $FA
	dw \1
ENDM
MACRO env_ret
	db $FB
ENDM
MACRO env_loop
	db $FC, \1
ENDM
MACRO env_endloop
	db $FD
ENDM
MACRO env_end
	db $FF
ENDM

; ---- tables ----
MACRO dwbe          ; big-endian word (period table)
	db HIGH(\1), LOW(\1)
ENDM
MACRO instr         ; attack envelope, release envelope
	dw \1, \2
ENDM
'''

HW_INC = r'''; hardware registers used by the sound code
DEF rP1 EQU $FF00
DEF rDIV EQU $FF04
DEF rTIMA EQU $FF05
DEF rTMA EQU $FF06
DEF rTAC EQU $FF07
DEF rIF EQU $FF0F
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
DEF rDMA EQU $FF46
DEF rIE EQU $FFFF
'''

A_PRESERVING = re.compile(r'^(ld (l|h|e|d|c|b|\[hl\]),|ld \[hl\], |push|pop (bc|de|hl)|inc (hl|de|bc|l|h|e|d|c|b)|dec (hl|de|bc|l|h|e|d|c|b)$|cp |bit |set |res |nop)')


def low_idiom_hints(g, arrays, page, base_name=None):
    """In the code, rewrite `ld a,$NN`/`add a,$NN` that build low bytes of RAM array addresses
    (h = page) as LOW(array) / LOW(B - A).  arrays: set of array start addresses."""
    from sm83 import Ins
    lows = {a & 0xFF: a for a in arrays if (a >> 8) == page}
    addrs = sorted(a for a, it in g.items.items() if it.kind == 'code')
    base = None
    for a in addrs:
        it = g.items[a]
        ins = it.text
        txt = (ins.mn + ' ' + ins.ops).strip()
        if a in g.labels:
            base = None
        if a in g.hints:
            base = None
            continue
        m = re.match(r'ld a,\$([0-9A-F]{2})$', txt)
        if m:
            v = int(m.group(1), 16)
            nxt = g.items.get(a + 2)
            nt = (nxt.text.mn + ' ' + nxt.text.ops) if nxt and nxt.kind == 'code' else ''
            if v in lows and nt in ('add a,b', 'add a,c', 'add a,[hl]'):
                g.hints[a] = 'ld a, LOW(%s)' % g.ram[lows[v]]
                base = lows[v]
                continue
            base = None
            continue
        m = re.match(r'add a,\$([0-9A-F]{2})$', txt)
        if m and base is not None:
            v = int(m.group(1), 16)
            tgt = (base & 0xFF00) | ((base + v) & 0xFF)
            if tgt in arrays:
                g.hints[a] = 'add a, LOW(%s - %s)' % (g.ram[tgt], g.ram[base])
                base = tgt
                continue
            base = None
            continue
        if txt in ('add a,b', 'add a,c') or A_PRESERVING.match(txt) or txt in ('ld l,a', 'ld [hl],a', 'ld h,$%02X' % page):
            if txt == 'ld h,$%02X' % page:
                g.hints[a] = 'ld h, HIGH(%s)' % (base_name or g.ram[min(arrays)])
            continue
        base = None


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', newline='\n') as f:
        f.write(text)


ROUTINE_COMMENTS = {
    'Sound_Init': ['; Sound_Init: master on, NR50=$77, NR51=$FF, full volume, shadow registers invalidated ($AA),',
                   '; load the initial wave, stop music and SFX, write the registers and retrigger all channels.'],
    'Sound_PlaySfx': ['; Sound_PlaySfx: a = SFX number ($FF = stop all SFX).',
                      '; If an SFX already owns one of the new SFX\'s channels, the new one is refused when its',
                      '; priority number is higher than the playing one\'s (lower number = more important);',
                      '; otherwise the old SFX track is stopped. Tracks are then taken from track 3 downward.'],
    'Sound_UpdateSfxChannels': ['; wSfxChannels = OR of the channel masks of the SFX tracks still running.'],
    'Sound_StopSfx': ['; stop SFX tracks 0-3 and reset the SFX register image.'],
    'Sound_StartTrack': ['; Sound_StartTrack: c = track, de -> header entry - 1. Reads pointer + channel byte,',
                         '; resets the per-track state (base note $24, volume, instrument, length set, tuning, stacks).'],
    'Sound_PlaySong': ['; Sound_PlaySong: a = song number ($FF = stop). Stops tracks 4-7, resets the music register',
                       '; image, then starts the header\'s tracks from track 7 downward.'],
    'Sound_Update': ['; Sound_Update: once per tick. For each active track (7 down to 0): main stream, release',
                     '; check, envelope stream. Then the SFX channel masks, and the register images are written:',
                     '; for each channel the SFX image if an SFX owns it, else the music image. Only changed bytes',
                     '; are written; a changed NRx2 retriggers the channel. NR51 is built from the pan bytes.'],
    'Sound_WriteRegs': ['; compare the chosen image with wHwRegs and write the changed registers.'],
    'Track_Main': ['; Track_Main: b = track, de = stream pointer. Counts wTrkWait down; at 0 reads bytes until',
                   '; a note, rest or hold sets a new wait.'],
    'Track_NoteOn': ['; note: wait = length; release counter = $FF or length*gate/256; start the instrument envelope.'],
    'Track_StartEnvelope': ['; point the envelope stream at the instrument\'s attack envelope (unless STATIC).'],
    'Track_ReadLength': ['; length: LLL = 6 -> next byte, else LengthSets[wTrkLengthSet + LLL].'],
    'Track_Command': ['; $E0-$FF commands. Unlisted values fall through to the flow-control handler, which ignores',
                      '; them: the same byte is then read again forever.'],
    'Track_Flow': ['; flow control for the main stream: stack pointer = wSoundStacks + wTrkStack[b].'],
    'Stream_Flow': ['; $F8 jump, $FA call (push return), $FB return, $FC loop start (push count+address),',
                    '; $FD loop end (count down, jump back or pop). hl = stack pointer, de = stream.'],
    'Track_SetNote': ['; a = note index -> period from the tuning table (big-endian words; index*2 via rlc).'],
    'Track_SetPeriod': ['; de = period -> image NRx3/NRx4 (ch3: also NR30 = $80).'],
    'Track_Release': ['; release counter: when it reaches 0, switch the envelope to the instrument\'s release envelope.'],
    'Track_Env': ['; Track_Env: envelope (instrument macro) stream, own wait counter and stack.'],
    'LoadWave': ['; copy 16 bytes from hl to wave RAM.'],
    'Track_SetVolume': ['; a = envelope volume (low nibble of wTrkVolume); falls into Track_ApplyVolume.'],
    'Track_ApplyVolume': ['; output volume = env volume - (15 - channel volume) - (15 - master), clamped at 0;',
                          '; NRx2 high nibble, or NR32 through Ch3VolumeTable.'],
    'Multiply_AxE': ['; h = a*e/256 via the game\'s floor(i*i/2) table at $DC00 (lo) / $DD00 (hi).'],
}


def apply_comments(g, extra=None):
    d = dict(ROUTINE_COMMENTS)
    if extra:
        d.update(extra)
    for a, n in g.labels.items():
        if n in d:
            g.block_comments[a] = [''] + d[n]


BUILD_CHECK = r'''#!/bin/sh
# Assemble the sound driver, link it over the original ROM, and compare.
# usage: sh build_check.sh <original rom>      (rgbasm/rgblink on PATH, or RGBDS=<dir>)
ROM="$1"
RGB="${RGBDS:+$RGBDS/}"
set -e
cd "$(dirname "$0")"
${RGB}rgbasm -Wall -o {P}_Sound.o {P}_Sound.asm
${RGB}rgblink -O "$ROM" -o {P}_rebuilt.gb {P}_Sound.o
if cmp -s "$ROM" {P}_rebuilt.gb; then echo "OK: {P} byte-exact"; else echo "MISMATCH"; cmp -l "$ROM" {P}_rebuilt.gb | head; exit 1; fi
'''


def write_build_check(out, P):
    write(os.path.join(out, 'build_check.sh'), BUILD_CHECK.replace('{P}', P))
