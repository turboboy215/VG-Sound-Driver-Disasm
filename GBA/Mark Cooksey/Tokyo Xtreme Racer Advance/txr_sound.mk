# Usage: make -f txr_sound.mk            rebuild the Tokyo Xtreme Racer Advance sound driver and data
#        make -f txr_sound.mk check ROM="Tokyo Xtreme Racer Advance (E) (M5).gba"
#                                        ...and compare every range with the ROM

AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi -mthumb
ROM    ?= Tokyo Xtreme Racer Advance (E) (M5).gba

BINS = txr_musicdrv.bin txr_musicdata.bin txr_fadetab.bin

all: $(BINS)

txr_sound.elf: txr_musicdrv.o txr_sound.ld
	$(LD) -T txr_sound.ld -o $@ txr_musicdrv.o
txr_musicdrv.bin: txr_sound.elf
	$(OBJCOPY) -O binary -j .musicdrv $< $@

txr_sound_data.o: txr_sound_data.s txr_pcm.bin
txr_sound_data.elf: txr_sound_data.o txr_sound_data.ld
	$(LD) -T txr_sound_data.ld -o $@ txr_sound_data.o
txr_musicdata.bin: txr_sound_data.elf
	$(OBJCOPY) -O binary -j .musicdata $< $@
txr_fadetab.bin: txr_sound_data.elf
	$(OBJCOPY) -O binary -j .fadetab $< $@

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

check: $(BINS)
	tail -c +24301 "$(ROM)" | head -c 7068 | cmp - txr_musicdrv.bin && echo "musicdrv 08005EEC-08007A88 OK"
	tail -c +3434225 "$(ROM)" | head -c 584620 | cmp - txr_musicdata.bin && echo "musicdata 083466F0-083D529C OK"
	tail -c +241241 "$(ROM)" | head -c 36 | cmp - txr_fadetab.bin && echo "fadetab 0803AE58-0803AE7C OK"

clean:
	rm -f *.o *.elf $(BINS)

.PHONY: all check clean
