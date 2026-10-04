/* Link the WarioWare sound driver and its data at their ROM addresses. */
SECTIONS
{
    .snd_pcm    0x08155D74 : { ww_sample_data.o(.snd_pcm) }
    .snd_code   0x080F05B4 : { ww_sound.o(.snd_code) }
    .snd_rodata 0x083FD1CC : { ww_sound_rodata.o(.snd_rodata) }
    .snd_data   0x083FD770 : { ww_music_data.o(.snd_data) }
    .snd_midi   0x0841BE80 : { ww_midi_data.o(.snd_midi) }
    /DISCARD/ : { *(.text) *(.data) *(.bss) *(.ARM.attributes) }
}
