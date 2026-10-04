/* Places every reconstructed piece of GBAModPlay v2 (Aero) at its ROM address. */
SECTIONS
{
    .gmp2_data    0x08036220 : { *(.gmp2_data) }      /* modules, sample bank, SFX bank */
    .gmp2_player  0x081036C4 : { *(.text.gmp2_player) }
    .gmp2_arm     0x08104980 : { *(.text.gmp2_arm) }
    .gmp2_rodata  0x08356E5C : { *(.gmp2_rodata) }
    .gmp2_bufsize 0x08357AB0 : { *(.gmp2_bufsize) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
