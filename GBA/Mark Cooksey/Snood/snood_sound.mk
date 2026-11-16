# Usage: make -f snood_sound.mk            rebuild the Snood sound driver and data
#        make -f snood_sound.mk check ROM="Snood (E) (M5).gba"
#                                       ...and compare every range with the ROM

AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi -mthumb
ROM    ?= Snood (E) (M5).gba

BINS = snood_musicdrv.bin snood_musicdata.bin

all: $(BINS)

snood_sound.elf: snood_musicdrv.o snood_sound.ld
	$(LD) -T snood_sound.ld -o $@ snood_musicdrv.o
snood_musicdrv.bin: snood_sound.elf
	$(OBJCOPY) -O binary -j .musicdrv $< $@

snood_sound_data.o: snood_sound_data.s snood_pcm.bin
snood_sound_data.elf: snood_sound_data.o snood_sound_data.ld
	$(LD) -T snood_sound_data.ld -o $@ snood_sound_data.o
snood_musicdata.bin: snood_sound_data.elf
	$(OBJCOPY) -O binary -j .musicdata $< $@

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: $(BINS)
	tail -c +150269 "$(ROM)" | head -c 4516 | cmp - snood_musicdrv.bin && echo "musicdrv 08024AFC-08025CA0 OK"
	tail -c +3473133 "$(ROM)" | head -c 719252 | cmp - snood_musicdata.bin && echo "musicdata 0834FEEC-083FF880 OK"

clean:
	rm -f *.o *.elf $(BINS)

.PHONY: all check clean
