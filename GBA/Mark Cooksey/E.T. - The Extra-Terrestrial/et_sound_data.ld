/* Places the music data blob and the WAV SFX table at their ROM addresses. */
SECTIONS
{
    .musicdata 0x08016790 : { *(.text) }
    .sfxtable  0x080284FC : { *(.sfxtable) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.data) *(.bss) }
}
