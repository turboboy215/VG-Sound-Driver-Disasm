# Usage: make -f et_sound.mk
# Rebuild the E.T. sound modules and compare them with the ROM.
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi -mthumb

all: et_musicdrv.bin et_sfxwav.bin et_sound_data.bin et_sfxtable.bin

et_sound.elf: et_musicdrv.o et_sfxwav.o et_sound.ld
	$(LD) -T et_sound.ld -o $@ et_musicdrv.o et_sfxwav.o

et_musicdrv.bin: et_sound.elf
	$(OBJCOPY) -O binary -j .musicdrv $< $@
et_sfxwav.bin: et_sound.elf
	$(OBJCOPY) -O binary -j .sfxwav $< $@

et_sound_data.o: et_sound_data.s et_music_samples.bin
et_sound_data.elf: et_sound_data.o et_sound_data.ld
	$(LD) -T et_sound_data.ld -o $@ et_sound_data.o
et_sound_data.bin: et_sound_data.elf
	$(OBJCOPY) -O binary -j .musicdata $< $@
et_sfxtable.bin: et_sound_data.elf
	$(OBJCOPY) -O binary -j .sfxtable $< $@

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f *.o *.elf et_musicdrv.bin et_sfxwav.bin et_sound_data.bin et_sfxtable.bin
