/* wf2.ld -- places every reconstructed piece of the Webfoot sound engine of Dragon Ball Z: The Legacy of Goku II at its ROM address. */
SECTIONS
{
    .wf2_sound    0x0801FE84 : { *(.wf2_sound) }
    .wf2_data     0x08313D10 : { *(.wf2_data) }
    .wf2_rodata   0x087D61A8 : { *(.wf2_rodata) }
    .wf2_iwram    0x03000520 : AT(0x087D744C) { *(.wf2_iwram) }   /* IWRAM code, stored in the crt0 RW image */
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
