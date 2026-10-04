import sys; sys.path.insert(0,'/root/w/tools'); import m68listing as M, m68annot as A
ij=open('/root/w/ij.bin','rb').read(); s2=open('/root/w/s2.bin','rb').read()
t_ij="""Indiana Jones and the Last Crusade (JE) - 68000 side of the Tiertex sound engine
capstone disassembly, labels/comments added. Data tables are described in Tiertex_SoundEngine.md
Z80 driver image $F0E2-$F6F7 is disassembled separately (IndyJones_Z80_driver.asm)"""
t_s2="""Strider II (E) - 68000 side of the Tiertex sound engine (+ speech unpacker)
capstone disassembly, labels/comments added. Data tables are described in Tiertex_SoundEngine.md
Z80 driver image $327D8-$32F13 is disassembled separately (Strider2_Z80_driver.asm)"""
open('/root/w/dis/IndyJones_68k_sound.asm','w').write(M.render(ij,[(0x274,0x2D6,'VBlank excerpt: music cue -> SFX'),(0xF07E,0xF0E2,'Driver loader'),(0xF6F8,0xFB14,'Sound API')],A.IJ_LABELS,A.IJ_C,t_ij))
open('/root/w/dis/Strider2_68k_sound.asm','w').write(M.render(s2,[(0x246,0x2A0,'VBlank excerpt: music cue -> SFX'),(0x3278A,0x327D8,'Driver loader'),(0x32F14,0x33480,'Sound API'),
   (0x39E8,0x3AAA,'Speech loader'),(0xBCAC,0xBCDA,'Huffman tree builder (byte format)'),(0xBE70,0xBF52,'Huffman unpacker (byte format)'),(0xBF52,0xC106,'Huffman tree builder + unpacker (nibble format)')],A.S2_LABELS,A.S2_C,t_s2))
