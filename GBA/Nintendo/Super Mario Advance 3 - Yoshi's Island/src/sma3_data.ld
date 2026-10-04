SECTIONS {
  .snd_data   0x083A8274 : { *(.snd_data) }
  .snd_config 0x083A7810 : { *(.snd_config) }
  /DISCARD/ : { *(.ARM.attributes) *(.text) *(.data) *(.bss) }
}
