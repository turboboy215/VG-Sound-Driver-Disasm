/* Links the reconstructed driver at its original ROM address. */
SECTIONS
{
    .musicdrv 0x08024AFC : { *(.text.snood_musicdrv) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
