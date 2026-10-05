/* link script for kr_sound.s: places each section at its ROM address */
SECTIONS
{
  .text.kr_sound            0x0803C128 : { *(.text.kr_sound) }
  .rodata.kr_sound_tables   0x08058AAC : { *(.rodata.kr_sound_tables) }
  .rodata.kr_sound_cmds     0x083FBD08 : { *(.rodata.kr_sound_cmds) }
  /DISCARD/ : { *(.ARM.attributes) *(.comment) }
}
