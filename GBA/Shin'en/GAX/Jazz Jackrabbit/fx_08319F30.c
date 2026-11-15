#include "gax.h"

void GAXFx_open(GAX_FX_channel *fxch)
{
    GAXTracker_open(&fxch->fxch);
    fxch->fxfreq = 0;
    fxch->fxnote = 0;
    fxch->fxvol = 0;
    *(u8 *)&fxch->fxid = 0;
    fxch->nofixedfreq = FALSE;
    fxch->fxch.unk1 = GAX_ram->unk5B;
    fxch->fxch.channel_index = -1;
    if (GAX_ram->fx_pitch == 0)
        GAX_ram->fx_pitch = 0x100000000ULL / GAX_ram->current_buf->mixrate;
}
