# Rebuild the sound driver and sound data of each build and compare them with the ROMs.
#   make -f nsnd.mk check   (named Makefile in the tools' own tree)
#           (the ROMs are looked up in $NSND_ROMDIR, NintSMA/ or the folder above it,
#                         as sma2.gba ... zelda.gba or under their original file names)
MAKEFLAGS += -r
.SUFFIXES:
.SECONDARY:
AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
ASFLAGS = -mcpu=arm7tdmi -mthumb-interwork -I.
CODE    = sma2 sma3 sma4 zelda sma2_mb sma3_mb sma4_mb
DATA    = sma2 sma3 sma4 zelda

all: $(CODE:%=%.elf) $(DATA:%=%_data.elf)

%_sound.o: %_sound.s nsnd.inc %_ram.inc
	$(AS) $(ASFLAGS) -o $@ $<
%_sound_rodata.o: %_sound_rodata.s
	$(AS) $(ASFLAGS) -o $@ $<
%.elf: %_sound.o %_sound_rodata.o %.ld
	$(LD) -T $*.ld -o $@ $*_sound.o $*_sound_rodata.o
%_pcm.bin:
	python3 ../tools/nsnd_tool.py extract-pcm $*
%_sound_data.o: %_sound_data.s nsnd_macros.inc %_pcm.bin
	$(AS) $(ASFLAGS) -o $@ $<
%_data.elf: %_sound_data.o %_data.ld
	$(LD) -T $*_data.ld -o $@ $<

check: all
	python3 romcheck.py

clean:
	rm -f *.o *.elf *.bin
