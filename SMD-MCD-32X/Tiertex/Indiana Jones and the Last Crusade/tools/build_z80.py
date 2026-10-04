import sys; sys.path.insert(0,'/root/w/tools'); import z80listing as z
hdr_ij = """Indiana Jones and the Last Crusade (JE) - Mega Drive
Tiertex sound driver (Z80 side), by Donald Campbell
Source: ROM $00F0E2-$00F6F7 ($616 bytes), copied to Z80 RAM $0000 by 68k LoadSoundDriver ($00F092)
Default voice bank ROM $00FEF8 ($3E0 bytes) -> Z80 $0A00
Disassembled with z80dasm, labels/comments added. See Tiertex_SoundEngine.md for the data format."""
hdr_s2 = """Strider II (E) - Mega Drive
Tiertex sound driver (Z80 side), by Donald Campbell - revision with portamento (cmd F3)
Source: ROM $0327D8-$032F13 ($73C bytes), copied to Z80 RAM $0000 by 68k LoadSoundDriver ($03279E)
Disassembled with z80dasm, labels/comments added. See Tiertex_SoundEngine.md for the data format."""
A=z.load('/root/w/tools/z80annot_ij.py'); open('/root/w/dis/IndyJones_Z80_driver.asm','w').write(z.render('/root/w/ij_z80.bin',A,hdr_ij))
B=z.load('/root/w/tools/z80annot_s2.py'); open('/root/w/dis/Strider2_Z80_driver.asm','w').write(z.render('/root/w/s2_z80.bin',B,hdr_s2))
