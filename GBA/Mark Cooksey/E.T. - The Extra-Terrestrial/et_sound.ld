/* Links the two reconstructed sound modules at their original ROM addresses. */
SECTIONS
{
    .musicdrv 0x080025EC : { *(.text.et_musicdrv) }
    .sfxwav   0x08004944 : { *(.text.et_sfxwav) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) }
}
