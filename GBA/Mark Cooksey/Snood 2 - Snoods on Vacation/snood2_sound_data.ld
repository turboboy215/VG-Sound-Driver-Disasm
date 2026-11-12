/* Places the Snood 2: Snoods on Vacation sound data at its ROM addresses. */
SECTIONS
{
    .steptab    0x0800FB60 : { *(.steptab) }
    .musicdata  0x080128B4 : { *(.musicdata) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
