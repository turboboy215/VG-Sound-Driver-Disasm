/* Places every reconstructed piece of GBAModPlay v1 (Pinball) at its ROM address. */
SECTIONS
{
    .gmp1_player 0x08004234 : { *(.text.gmp1_player) }
    .gmp1_host   0x0800DD60 : { *(.text.gmp1_host) }
    .gmp1_arm    0x080CE0C0 : { *(.text.gmp1_arm) }
    .gmp1_data0  0x0805993C : { *(.gmp1_data0) }
    .gmp1_data1  0x0814CCF4 : { *(.gmp1_data1) }
    .gmp1_data2  0x0826A58C : { *(.gmp1_data2) }
    .gmp1_rodata 0x083C27C8 : { *(.gmp1_rodata) }
    /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.text) *(.data) *(.bss) }
}
