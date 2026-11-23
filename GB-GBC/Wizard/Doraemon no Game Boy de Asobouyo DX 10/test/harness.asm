; Test harness: links the reassembled driver into a small MBC1 ROM.
; Mailbox at $D800: op (0 none, 1 play [$D801], 2 stop all, 3 fade [$D801], 4 pause, 5 resume,
; 6 vol offset a=[$D801] b=[$D802], 7 stop except [$D801]). HarnessHook runs after every Sound_Update.
INCLUDE "SOUNDFILE"

DEF hOp EQU $D800
DEF hArg EQU $D801
DEF hArg2 EQU $D802

SECTION "header", ROM0[$0100]
    nop
    jp Start
    ds $0150 - @, 0

SECTION "harness", ROM0[$0150]
Start:
    di
    ld sp, $DFF0
    ld hl, $C000
    ld bc, $1F00
.clear
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clear
    ld a, 4
    ld [$2100], a
    call Sound_Init
MainLoop:
    ld a, [hOp]
    and a
    jr z, .update
    cp 1
    jr nz, .n2
    ld a, [hArg]
    ld c, a
    call Sound_Play
    jr .done
.n2 cp 2
    jr nz, .n3
    call Sound_StopAll
    jr .done
.n3 cp 3
    jr nz, .n4
    ld a, [hArg]
    call Sound_FadeOut
    jr .done
.n4 cp 4
    jr nz, .n5
    call Sound_Pause
    jr .done
.n5 cp 5
    jr nz, .n6
    call Sound_Resume
    jr .done
.n6 cp 6
    jr nz, .n7
    ld a, [hArg2]
    ld b, a
    ld a, [hArg]
    call Sound_SetVolOffset
    jr .done
.n7 ld a, [hArg]
    call Sound_StopExcept
.done
    xor a
    ld [hOp], a
.update
    call Sound_Update
HarnessHook::
    nop
    jr MainLoop
