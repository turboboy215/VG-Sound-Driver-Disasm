import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import z80listing as z
IJ = z.load(os.path.join(os.path.dirname(__file__), 'z80annot_ij.py'))
M, _, _, _ = z.addrmap(os.path.join(os.path.dirname(__file__), '../ij_z80.bin'), os.path.join(os.path.dirname(__file__), '../s2_z80.bin'))
def m(a):
    if a in M: return M[a]
    # data areas
    if 0x021D <= a < 0x023D: return a + 0x95
    if a == 0x030D: return 0x03A2
    if a >= 0x05FC: return a + 0x125
    return None
RAM = IJ.RAM
BLOCKS = [(0x0000,0x02B2,'code'),(0x02B2,0x02D2,'bytedata'),(0x02D2,0x03A2,'code'),(0x03A2,0x03C2,'worddata'),
          (0x03C2,0x0721,'code'),(0x0721,0x073C,'worddata')]
LABELS = {}
for a,v in IJ.LABELS.items():
    b = m(a)
    if b is not None: LABELS[b] = v
C = {}
for a,v in IJ.C.items():
    b = m(a)
    if b is not None: C[b] = v
PTRS = {m(a):v for a,v in IJ.PTRS.items() if m(a) is not None}
LABELS.update({
 0x01CA:('UT_Glide','[Strider II] per-tick portamento: IX+$22 steps left, IX+$25/26 step, IX+$23/24 F-num, IX+$27 block<<3.\n'
                    'F-num space wraps at $28E/$4D2 (octave = $244 units) with block -/+ 1.'),
 0x0216:('Glide_WrapDown',None), 0x0227:('Glide_SetBlock',None), 0x022E:('Glide_Write',None),
 0x025F:('UT_Return',None),
 0x053B:('Note_GlideCheck',None), 0x05C3:('Note_WriteFreqKeyOn',None),
 0x03C2:('Cmd_F3_Glide','[Strider II] F3 n: glide from current pitch into the next note over 2^n ticks'),
 0x054A:('Glide_Setup','[Strider II] next note with glide: step = (target - current)/2^n, normalised to the current block'),
 0x057B:('Glide_OctUp',None), 0x0585:('Glide_TargetLower',None), 0x0590:('Glide_OctDown',None),
 0x059A:('Glide_SameBlock',None), 0x059C:('Glide_Delta',None), 0x05A4:('Glide_ShiftLoop',None),
})
C.update({
 0x01CA:'glide active?', 0x01D8:'F-num += step', 0x01ED:'below $28E?', 0x01FB:'>= $4D2?',
 0x0203:'wrap: F-num - $244, block + 1', 0x0216:'wrap: F-num + $244, block - 1', 0x0241:'reg $A4+ch',
 0x024A:'reg $A0+ch', 0x0256:'key on (already on: no retrigger)', 0x03C4:'IX+$22 = shift n',
 0x053C:'glide requested?', 0x0542:'no: remember F-num as current pitch', 0x054C:'current block',
 0x0578:'+$244 per octave of difference', 0x05A2:'E = 2^n (step counter)', 0x05AD:'IX+$22 = steps',
 0x05B0:'IX+$25/26 = step', 0x05B8:'write current (start) pitch',
})
