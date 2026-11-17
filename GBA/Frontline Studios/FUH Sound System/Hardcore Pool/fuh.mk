# fuh.mk -- rebuild the FUH Sound System parts of Hardcore Pool (E) (M4) and compare with the ROM
#   make -f fuh.mk check ROM="Hardcore Pool (E) (M4).gba"
PREFIX ?= arm-none-eabi-
AS      = $(PREFIX)as
LD      = $(PREFIX)ld
PYTHON ?= python3
ASFLAGS = -mcpu=arm7tdmi
ROM    ?= Hardcore Pool (E) (M4).gba
OBJS    = fuh_sound.o fuh_rodata.o fuh_data.o

all: fuh.elf

fuh_sound.o: fuh_sound.s fuh_defs.inc
fuh_data.o: fuh_data.s fuh_data.inc fuh_music_pcm.bin fuh_sfx_pcm.bin

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

fuh.elf: $(OBJS) fuh.ld
	$(LD) -T fuh.ld -o $@ $(OBJS)

check: fuh.elf
	$(PYTHON) romcheck.py fuh.elf "$(ROM)"

clean:
	rm -f $(OBJS) fuh.elf

.PHONY: all check clean
