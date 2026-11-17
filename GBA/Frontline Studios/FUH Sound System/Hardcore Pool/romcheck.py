#!/usr/bin/env python3
"""romcheck.py ELF ROM -- compare every allocated section of ELF with the ROM at its load address.

Self-contained (no pyelftools): reads ELF32 little-endian section and program headers.
Exit status 0 if every section is byte-identical.
"""
import struct, sys

def sections(path):
    d = open(path, 'rb').read()
    assert d[:4] == b'\x7fELF' and d[4] == 1 and d[5] == 1, 'need ELF32 little-endian'
    (e_phoff, e_shoff) = struct.unpack_from('<II', d, 0x1C)
    e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx = struct.unpack_from('<HHHHH', d, 0x2A)
    phs = []
    for i in range(e_phnum):
        p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz = struct.unpack_from('<6I', d, e_phoff + i * e_phentsize)
        if p_type == 1:
            phs.append((p_offset, p_vaddr, p_paddr, p_filesz))
    shs = [struct.unpack_from('<10I', d, e_shoff + i * e_shentsize) for i in range(e_shnum)]
    stroff = shs[e_shstrndx][4]
    for sh in shs:
        name_off, typ, flags, addr, offset, size = sh[:6]
        if not (flags & 2) or typ != 1 or size == 0:   # SHF_ALLOC, SHT_PROGBITS
            continue
        name = d[stroff + name_off:d.index(b'\0', stroff + name_off)].decode()
        lma = addr
        for (po, pv, pp, pf) in phs:
            if po <= offset < po + pf:
                lma = pp + (offset - po)
        yield name, addr, lma, d[offset:offset + size]

def main():
    elf, rom = sys.argv[1], open(sys.argv[2], 'rb').read()
    bad = 0
    total = 0
    for name, vma, lma, data in sections(elf):
        o = lma - 0x08000000
        ref = rom[o:o + len(data)]
        total += len(data)
        if ref == data:
            print('OK    %-24s ROM %08X-%08X  (%d bytes)' % (name, lma, lma + len(data), len(data)))
        else:
            bad += 1
            first = next(i for i in range(len(data)) if i >= len(ref) or ref[i] != data[i])
            print('DIFF  %-24s ROM %08X-%08X  first difference at %08X (VMA %08X): rom %s built %s'
                  % (name, lma, lma + len(data), lma + first, vma + first,
                     ref[first:first + 4].hex(), data[first:first + 4].hex()))
    print('%d section(s) differ' % bad if bad else 'all sections identical (%d bytes)' % total)
    sys.exit(1 if bad else 0)

main()
