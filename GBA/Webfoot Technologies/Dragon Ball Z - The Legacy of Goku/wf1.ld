/* wf1.ld -- places every reconstructed piece of the Webfoot sound engine of Dragon Ball Z: The Legacy of Goku at its ROM address. */
SECTIONS
{
    .wf1_mix      0x080089EC : { *(.wf1_mix) }
    .wf1_player   0x08009CCC : { *(.wf1_player) }
    .wf1_sound    0x0800A9F4 : { *(.wf1_sound) }
    .wf1_rodata   0x080113A8 : { *(.wf1_rodata) }
    .wf1_masktab  0x08142518 : { *(.wf1_masktab) }
    .wf1_fxtab    0x0818CDF8 : { *(.wf1_fxtab) }
    .wf1_data     0x0856A7D4 : { *(.wf1_data) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
