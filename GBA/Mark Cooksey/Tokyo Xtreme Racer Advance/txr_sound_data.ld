/* Places the Tokyo Xtreme Racer Advance sound data at its ROM addresses. */
SECTIONS
{
    .musicdata  0x083466F0 : { *(.musicdata) }
    .fadetab    0x0803AE58 : { *(.fadetab) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
