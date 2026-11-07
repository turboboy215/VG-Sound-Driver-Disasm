SECTIONS
{
    .text.som_sound 0x080A0510 : { *(.text.som_sound) }
    .text.som_veneer 0x0836D8A4 : { *(.text.som_veneer) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) }
}
