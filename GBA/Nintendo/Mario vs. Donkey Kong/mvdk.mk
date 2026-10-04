# make -f mvdk.mk check ROM="Mario vs. Donkey Kong (E) (M5).gba"
AS=arm-none-eabi-as
LD=arm-none-eabi-ld
ASFLAGS=-mcpu=arm7tdmi
SRCS=mvdk_sound_thumb.s mvdk_sound_arm.s mvdk_sound_rodata.s mvdk_sfx_data.s mvdk_music_data.s
OBJS=$(SRCS:.s=.o)
ROM?=Mario vs. Donkey Kong (E) (M5).gba
all: mvdk_sound.elf
%.o: %.s mvdk_sound.inc
	$(AS) $(ASFLAGS) -o $@ $<
mvdk_sound.elf: $(OBJS) mvdk.ld
	$(LD) -T mvdk.ld -o $@ $(OBJS)
check: mvdk_sound.elf
	python3 romcheck.py mvdk_sound.elf "$(ROM)"
clean:
	rm -f $(OBJS) mvdk_sound.elf
