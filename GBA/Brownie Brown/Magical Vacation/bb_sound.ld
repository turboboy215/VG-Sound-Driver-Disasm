SECTIONS
{
    .text.bb_sound 0x0805B564 : { *(.text.bb_sound) }
    .text.bb_veneer 0x080C2044 : { *(.text.bb_veneer) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) }
}
