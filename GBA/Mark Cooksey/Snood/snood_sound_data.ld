/* Places the Snood sound data at its ROM address. */
SECTIONS
{
    .musicdata  0x0834FEEC : { *(.musicdata) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
