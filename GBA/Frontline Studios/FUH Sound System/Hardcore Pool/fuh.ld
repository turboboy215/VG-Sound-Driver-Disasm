/* fuh.ld -- place every FUH Sound System section of Hardcore Pool (E) (M4) at its ROM/IWRAM address */
OUTPUT_ARCH(arm)
SECTIONS
{
  .text.fuh_vblank      0x08000190 : { *(.text.fuh_vblank) }
  .text.fuh_mixer       0x08035A00 : { *(.text.fuh_mixer) }
  .text.fuh_music       0x08039260 : { *(.text.fuh_music) }
  .rodata.fuh_music     0x0832A954 : { *(.rodata.fuh_music) }
  .rodata.fuh_sfx       0x0839D868 : { *(.rodata.fuh_sfx) }
  .rodata.fuh_steptab   0x083E1E00 : { *(.rodata.fuh_steptab) }
  /* ARM code that crt0 copies from the ROM IWRAM image (083EC724 -> 03000000) */
  .iwram.fuh_mix        0x03000408 : AT(0x083ECB2C) { *(.iwram.fuh_mix) }
  .iwram.fuh_player     0x03002838 : AT(0x083EEF5C) { *(.iwram.fuh_player) }
  /DISCARD/ : { *(.ARM.attributes) *(.comment) }
}
