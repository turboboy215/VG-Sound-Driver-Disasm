/* Links the reconstructed driver at its original ROM address. */
SECTIONS
{
    .musicdrv 0x08005EEC : { *(.text.txr_musicdrv) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
