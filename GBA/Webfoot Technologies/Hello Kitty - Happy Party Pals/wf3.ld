/* wf3.ld -- places every reconstructed piece of the Webfoot sound engine of Hello Kitty: Happy Party Pals at its ROM address. */
SECTIONS
{
    .wf3_sound    0x08027F04 : { *(.wf3_sound) }
    .wf3_data     0x08035EA4 : { *(.wf3_data) }
    .wf3_rodata   0x0837CD40 : { *(.wf3_rodata) }
    .wf3_iwram    0x03000828 : AT(0x0837E6B0) { *(.wf3_iwram) }   /* IWRAM code, stored in the crt0 RW image */
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
