/* Links every part of the MvDK sound driver at its original ROM address. */
OUTPUT_ARCH(arm)
SECTIONS {
  .snd_arm_a    0x0800023C : { *(.snd_arm_a) }
  .snd_arm_b    0x08001840 : { *(.snd_arm_b) }
  .snd_thumb    0x080725D8 : { *(.snd_thumb) }
  .snd_sfxnames 0x0807A2D0 : { *(.snd_sfxnames) }
  .snd_rodata   0x08B91F60 : { *(.snd_rodata) }
  .snd_sfx      0x08B92E20 : { *(.snd_sfx) }
  .snd_music    0x08DDD85C : { *(.snd_music) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
