/* Links the reconstructed driver at its original ROM address. */
SECTIONS
{
    .musicdrv 0x0800097C : { *(.text.snood2_musicdrv) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
