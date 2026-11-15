#include "gax.h"

u8 *GAX_code2ram(u8 *startaddr, u8 *endaddr)
{
    s32 sz = endaddr - startaddr;
    u8 *out = GAX_alloc(sz);
    CpuSet(startaddr, out, ((sz / 4) & 0x1FFFFF) | (1 << 26));
    return out;
}
