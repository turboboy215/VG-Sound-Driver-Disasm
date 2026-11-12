# Usage: make -f snood2_sound.mk            rebuild the Snood 2: Snoods on Vacation sound driver and data
#        make -f snood2_sound.mk check ROM="Snood 2 - Snoods on Vacation (E) (M5).gba"
#                                        ...and compare every range with the ROM

AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi -mthumb
ROM    ?= Snood 2 - Snoods on Vacation (E) (M5).gba

BINS = snood2_musicdrv.bin snood2_steptab.bin snood2_musicdata.bin

all: $(BINS)

snood2_sound.elf: snood2_musicdrv.o snood2_sound.ld
	$(LD) -T snood2_sound.ld -o $@ snood2_musicdrv.o
snood2_musicdrv.bin: snood2_sound.elf
	$(OBJCOPY) -O binary -j .musicdrv $< $@

snood2_sound_data.o: snood2_sound_data.s snood2_pcm.bin
snood2_sound_data.elf: snood2_sound_data.o snood2_sound_data.ld
	$(LD) -T snood2_sound_data.ld -o $@ snood2_sound_data.o
snood2_steptab.bin: snood2_sound_data.elf
	$(OBJCOPY) -O binary -j .steptab $< $@
snood2_musicdata.bin: snood2_sound_data.elf
	$(OBJCOPY) -O binary -j .musicdata $< $@

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: $(BINS)
	tail -c +2429 "$(ROM)" | head -c 6960 | cmp - snood2_musicdrv.bin && echo "musicdrv 0800097C-080024AC OK"
	tail -c +64353 "$(ROM)" | head -c 1572 | cmp - snood2_steptab.bin && echo "steptab 0800FB60-08010184 OK"
	tail -c +75957 "$(ROM)" | head -c 522080 | cmp - snood2_musicdata.bin && echo "musicdata 080128B4-08092014 OK"

clean:
	rm -f *.o *.elf $(BINS)

.PHONY: all check clean
