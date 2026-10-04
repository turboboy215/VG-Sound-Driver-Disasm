# Rebuild the WarioWare, Inc. (E) sound driver and data and compare them with the ROM.
#   make -f ww.mk check ROM="WarioWare Inc. (E) (M5).gba"
# Needs arm-none-eabi-as/ld/objcopy and python3.
ROM     ?= WarioWare Inc. (E) (M5).gba
PREFIX  ?= arm-none-eabi-
AS      := $(PREFIX)as
LD      := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy
ASFLAGS := -mcpu=arm7tdmi
OBJS    := ww_sound.o ww_sound_rodata.o ww_music_data.o ww_midi_data.o ww_sample_data.o

check: ww_sound.elf
	OBJCOPY=$(OBJCOPY) python3 romcheck.py "$(ROM)" ww_sound.elf

ww_sound.elf: $(OBJS) ww.ld
	$(LD) -T ww.ld -o $@ $(OBJS)

extracted.stamp:
	python3 ww_tool.py extract "$(ROM)" .
	touch $@

ww_midi_data.o ww_sample_data.o: extracted.stamp
ww_music_data.o: ww_macros.inc

%.o: %.s ww_sound.inc
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(OBJS) ww_sound.elf extracted.stamp ww_sample_pcm.bin
	rm -rf midi

.PHONY: check clean
