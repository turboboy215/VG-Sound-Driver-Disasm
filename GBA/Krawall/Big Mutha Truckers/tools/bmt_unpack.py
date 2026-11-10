#!/usr/bin/env python3
"""Unpack Big Mutha Truckers' packed Krawall music blobs by running the game's own
IWRAM decompressor (ROM 0x3EA228 -> 0x03000000, entry 0x030026D0) under Unicorn,
then rebuild the Krawall Module exactly as BMT's loader (0x08032150) does."""
import struct, sys, json
from unicorn import Uc, UC_ARCH_ARM, UC_MODE_ARM, UC_HOOK_CODE
from unicorn.arm_const import *

ROM = open(sys.argv[1], 'rb').read()
OUT = sys.argv[2]
IWRAM_LMA, IWRAM_LEN = 0x3EA228, 0x374C
SAMPLE_LIST = 0x177080
BLOBS = [0x1771f0, 0x177310, 0x177680, 0x177f10, 0x1783e0, 0x1789e0, 0x178ca0,
         0x179360, 0x179660, 0x17a050, 0x17ac90, 0x17b7a0, 0x17c190, 0x17ca10]
DST = 0x02010000
STOP = 0x02FFF000

def decompress(src_rom_off):
    mu = Uc(UC_ARCH_ARM, UC_MODE_ARM)
    mu.mem_map(0x08000000, 0x02000000)
    mu.mem_write(0x08000000, ROM)
    mu.mem_map(0x03000000, 0x8000)
    mu.mem_write(0x03000000, ROM[IWRAM_LMA:IWRAM_LMA + IWRAM_LEN])
    mu.mem_map(0x02000000, 0x01000000)
    mu.reg_write(UC_ARM_REG_SP, 0x03007E00)
    mu.reg_write(UC_ARM_REG_R0, 0x08000000 + src_rom_off)
    mu.reg_write(UC_ARM_REG_R1, DST)
    mu.reg_write(UC_ARM_REG_LR, STOP)
    mu.emu_start(0x030026D0, STOP, count=200_000_000)
    return mu

def unpack(blob):
    p = blob
    nsmp = ROM[p]; p += 1
    smp_idx = list(ROM[p:p + nsmp]); p += nsmp
    p = (p + 3) & ~3
    size = ROM[p] | ROM[p + 1] << 8 | ROM[p + 2] << 16
    mu = decompress(p)
    data = bytes(mu.mem_read(DST, size))
    npat = data[-1]
    ninst = data[-2]
    mod_off = size - (npat * 4 + 0x172) - ninst * 0x130
    return dict(blob=blob, samples=smp_idx, size=size, npat=npat, ninst=ninst,
                mod_off=mod_off, data=data)

if __name__ == '__main__':
    res = []
    for b in BLOBS:
        u = unpack(b)
        d = u['data']; m = u['mod_off']
        open(f"{OUT}/bmt_{b:06x}.bin", 'wb').write(d)
        hdr = dict(blob=hex(b), size=u['size'], samples=u['samples'], npat=u['npat'],
                   ninst=u['ninst'], mod_off=hex(m),
                   channels=d[m], numOrders=d[m + 1], songRestart=d[m + 2],
                   order=list(d[m + 3:m + 3 + d[m + 1]]),
                   volGlobal=d[m + 0x163], speed=d[m + 0x164], bpm=d[m + 0x165],
                   flags=list(d[m + 0x166:m + 0x16C]),
                   field16C=hex(struct.unpack_from('<I', d, m + 0x16C)[0]),
                   pat_offs=[hex(struct.unpack_from('<I', d, m + 0x170 + 4 * i)[0]) for i in range(u['npat'])],
                   tail=d[-8:].hex())
        res.append(hdr)
        print(json.dumps(hdr))
    json.dump(res, open(f"{OUT}/bmt_modules.json", 'w'), indent=1)
