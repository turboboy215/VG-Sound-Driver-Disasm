/* Places every reconstructed piece of GBAModPlay v3 (NFSU2) at its ROM address. */
SECTIONS
{
    .gmp3_data    0x08000210 : { *(.gmp3_data) }      /* SFX bank, modules, sample bank */
    .gmp3_player  0x08135C84 : { *(.text.gmp3_player) }
    .gmp3_periods 0x08138220 : { *(.gmp3_periods) }
    .gmp3_arm     0x08141300 : { *(.text.gmp3_arm) }
    .gmp3_rodata  0x08756E8C : { *(.gmp3_rodata) }
    .gmp3_ratetab 0x0878E7AC : { *(.gmp3_ratetab) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
