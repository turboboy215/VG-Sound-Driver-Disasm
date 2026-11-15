#include "gax.h"

void GAX2_new(GAXParams *params)
{
    if (params == NULL) {
        GAX_ASSERT(GAX_str_GAX2_NEW, GAX_str_PARAMS_NULL);
        return;
    }
    GAX_memclr(params, sizeof(GAXParams));
    params->mixing_rate = -1;
    params->fx_mixing_rate = -1;
    params->filter_depth = 0;
    params->fx_channels = -1;
    params->volume = -1;
    params->debug = TRUE;
}

extern u8 GAXTracker_asm_0831A3FC[];
extern u8 GAXTracker_patch1_0831A450[];
extern u8 GAXTracker_patch2_0831A4CC[];
#define PATCH(lbl, o) (((u16 *)((u8 *)GAX_ram->gax_tracker_asm - (GAXTracker_asm_0831A3FC - (lbl))))[(o) / 2])
void GAX2_init_volboost(void)
{
    u16 volume = GAX_ram->replayer[GAX_ram->mix_buffer_id]->song_2->volume;
    if (volume > 512) {
        GAX_ram->volboost_level = 2;
        PATCH(GAXTracker_patch1_0831A450, 0) = PATCH(GAXTracker_patch2_0831A4CC, 0) = 0x90AB;
        PATCH(GAXTracker_patch1_0831A450, 4) = PATCH(GAXTracker_patch2_0831A4CC, 4) = 0xA0A8;
    } else if (volume > 256) {
        GAX_ram->volboost_level = 1;
        PATCH(GAXTracker_patch1_0831A450, 0) = PATCH(GAXTracker_patch2_0831A4CC, 0) = 0x912B;
        PATCH(GAXTracker_patch1_0831A450, 4) = PATCH(GAXTracker_patch2_0831A4CC, 4) = 0xA128;
    } else {
        GAX_ram->volboost_level = 0;
        PATCH(GAXTracker_patch1_0831A450, 0) = PATCH(GAXTracker_patch2_0831A4CC, 0) = 0x91AB;
        PATCH(GAXTracker_patch1_0831A450, 4) = PATCH(GAXTracker_patch2_0831A4CC, 4) = 0xA1A8;
    }
}

void GAX2_init_song(GAXSongData *song)
{
    s32 num_ch = song->num_channels;
    GAX_player *player;
    GAX_channel *ch;
    s32 i;
    u32 sum;

    player = (GAX_player *)GAX_alloc(sizeof(GAX_player));
    GAX_PLAYER() = player;
    ch = (GAX_channel *)GAX_alloc(num_ch * sizeof(GAX_channel));
    GAX_PLAYER()->channels = ch;
    GAX_PLAYER()->song_2 = song;
    for (i = 0; i < num_ch; i++)
        GAX_PLAYER()->channels[i].channel_index = i;
    if (GAX_ram->reverb_enabled) {
        sum = 0;
        GAX_PLAYER()->reverb_channels = song->reverb_channels;
        for (i = 0; i < 3; i++) {
            GAX_PLAYER()->reverb_delay[i] = song->reverb_delay[i] * GAX_ram->buf_header_dma1->mixrate / 1000 * 2;
            GAX_PLAYER()->reverb_decay[i] = song->reverb_decay[i];
            sum += song->reverb_decay[i];
        }
        GAX_PLAYER()->reverb_decay_sum = sum;
    }
    GAX2_init_volboost();
}

void GAX2_init_soundhw(void)
{
    int i;
    if (GAX_ram->buf_header_dma2 != NULL) {
        REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        GAX_DMA_DELAY();
        REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        REG_DMA2CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        GAX_DMA_DELAY();
        REG_DMA2CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        REG_DMA1CNT = 4;
        REG_DMA2CNT = 4;
        REG_SOUNDCNT_X = 0;
        REG_SOUNDCNT_H = 0xFB0C;
        for (i = 0; i < 8; i++) {
            REG_FIFO_A = 0;
            REG_FIFO_B = 0;
        }
        REG_DMA2DAD = REG_ADDR_FIFO_B;
        REG_DMA2SAD = GAX_ram->buffer_dma2;
    } else {
        REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        GAX_DMA_DELAY();
        REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        REG_DMA1CNT = 4;
        REG_SOUNDCNT_X = 0;
        REG_SOUNDCNT_H = 0xB04;
        for (i = 0; i < 8; i++)
            REG_FIFO_A = 0;
    }
    *(vu8 *)0x04000089 = 0x42;
    REG_DMA1DAD = REG_ADDR_FIFO_A;
    REG_DMA1SAD = GAX_ram->buffer_dma1;
}

void GAX_open(void)
{
    int i;
    GAXOutput_open(GAX_PLAYER());
    GAX_ram->current_buf = GAX_ram->buf_header_dma1;
    for (i = 0; i < GAX_PLAYER()->song_2->num_channels; i++) {
        GAXTracker_open(&GAX_PLAYER()->channels[i]);
        GAX_PLAYER()->channels[i].order = GAX_PLAYER()->song_2->order_lists[i];
    }
    GAXSync_open(GAX_PLAYER());
    GAX_PLAYER()->song = GAX_PLAYER()->song_2;
}
