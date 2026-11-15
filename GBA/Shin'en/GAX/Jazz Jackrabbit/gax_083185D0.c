#include "gax.h"

b8 GAX2_jingle(const void *jingle)
{
    u8 *mem;
    u32 size;
    GAX_ram->scratch_mem = mem = GAX_ram->jingle_mem;
    GAX_ram->scratch_mem_size = size = GAX_ram->jingle_mem_size;
    if (GAX_ram->params->flags & GAX_NO_JINGLES) {
        if (GAX_ram->params->debug)
            GAX_ASSERT(GAX_str_GAX2_JINGLE, GAX_str_NO_JINGLE);
        return FALSE;
    }
    GAX_memclr(mem, size);
    GAX_ram->irq_state = 0;
    GAX_ram->mix_buffer_id = 1;
    REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    if (GAX_ram->buf_header_dma2) {
        REG_DMA2CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        GAX_DMA_DELAY();
        REG_DMA2CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    }
    GAX2_init_song((GAXSongData *)jingle);
    GAX_open();
    GAX_PLAYER()->stop_on_songend = TRUE;
    GAX_ram->params->is_songend = FALSE;
    GAX_ram->params->is_jingleend = FALSE;
    GAX_ram->playback_state = 1;
    GAX_ram->irq_state = 1;
    return TRUE;
}

#define REG_TM0CNT_H (*(vu16 *)0x04000102)
#define REG_TM1CNT_H (*(vu16 *)0x04000106)
void GAX_irq(void)
{
    if (GAX_ram->signature == 0x47415833 && GAX_ram->irq_state) {
        if (GAX_ram->irq_state == 1) {
            GAX_ram->irq_state = 2;
            REG_SOUNDCNT_X = SOUND_MASTER_ENABLE;
            REG_TM0CNT_H = 0;
            REG_TM0CNT = (0x10000 - GAX_ram->timer_reload_dma1) | 0xC00000;
            if (GAX_ram->buf_header_dma2) {
                REG_TM1CNT_H = 0;
                REG_TM1CNT = (0x10000 - GAX_ram->timer_reload_dma2) | 0xC00000;
            }
        }
        if (GAX_ram->params->debug && !GAX_ram->irq_finished)
            GAX_ASSERT(GAX_str_GAX_IRQ, GAX_str_PLAY_NOT_FINISHED);
        if (GAX_ram->buffer_half == 1 && GAX_ram->irq_state > 1) {
            REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
            GAX_DMA_DELAY();
            REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
            if (GAX_ram->buf_header_dma2) {
                REG_DMA2CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
                GAX_DMA_DELAY();
                REG_DMA2CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
            }
            REG_DMA1SAD = GAX_ram->buffer_dma1 + (GAX_ram->buffer_half ^ 1) * GAX_ram->buf_header_dma1->timer_reload;
            REG_DMA1CNT_H = DMA_ENABLE | DMA_START_SPECIAL | DMA_32BIT | DMA_REPEAT | DMA_DEST_RELOAD;
            if (GAX_ram->buf_header_dma2) {
                REG_DMA2SAD = GAX_ram->buffer_dma2 + (GAX_ram->buffer_half ^ 1) * GAX_ram->buf_header_dma2->timer_reload;
                REG_DMA2CNT_H = DMA_ENABLE | DMA_START_SPECIAL | DMA_32BIT | DMA_REPEAT | DMA_DEST_RELOAD;
            }
        }
        GAX_ram->irq_finished = FALSE;
    }
}

void GAX_play(void)
{
    if (GAX_ram->irq_state) {
        GAXChannelInfo *ci = GAX_ram->params->channel_info;
        if (ci)
            GAX_memclr(ci, 64);
        if (GAX_ram->params->volume > 255)
            GAX_ram->params->volume = 255;
        GAX_PLAYER()->global_volume = GAX_ram->params->volume;
        GAX_ram->filt_depth = GAX_ram->params->filter_depth;
        GAX_PLAYER()->is_playing = TRUE;
        if (GAX_ram->playback_state == 0)
            GAXSync_render(GAX_PLAYER(), GAX_PLAYER()->timer);
        if (GAX_ram->buf_header_dma2) {
            GAX_ram->buf_id = 1;
            GAX_ram->current_buf = GAX_ram->buf_header_dma1;
            GAXOutput_stream(GAX_PLAYER(), GAX_ram->buffer_dma1 + GAX_ram->buf_header_dma1->timer_reload * GAX_ram->buffer_half);
            GAX_ram->buf_id = 2;
            GAX_ram->current_buf = GAX_ram->buf_header_dma2;
            GAXOutput_stream(GAX_PLAYER(), GAX_ram->buffer_dma2 + GAX_ram->buf_header_dma2->timer_reload * GAX_ram->buffer_half);
        } else {
            GAX_ram->buf_id = 0;
            GAX_ram->current_buf = GAX_ram->buf_header_dma1;
            GAXOutput_stream(GAX_PLAYER(), GAX_ram->buffer_dma1 + GAX_ram->buf_header_dma1->timer_reload * GAX_ram->buffer_half);
        }
        GAX_PLAYER()->timer++;
        GAX_ram->buffer_half ^= 1;
        GAX_ram->params->is_songend = GAX_PLAYER()->songend;
        if (GAX_ram->mix_buffer_id == 1 && GAX_ram->params->is_songend) {
            GAX_ram->mix_buffer_id = 0;
            GAX_ram->params->is_jingleend = TRUE;
            GAX2_init_volboost();
        }
        GAX_ram->irq_finished = TRUE;
    }
}

u32 GAX_fx(u32 fxid)
{
    s32 i;
    int curfxch = 0;
    int prio1;
    int prio2 = 0x7FFFFFFF;

    if (fxid < 256) {
        for (i = 0; i < GAX_ram->num_fx_channels; i++) {
            prio1 = GAX_ram->fx_channels[i].fxch.priority;
            if (prio1 <= prio2) {
                curfxch = i;
                prio2 = prio1;
            }
        }
        GAX_ram->fx_channels[curfxch].fxfreq = 8;
        GAX_ram->fx_channels[curfxch].fxnote = 0;
        GAX_ram->fx_channels[curfxch].nofixedfreq = FALSE;
        *(u8 *)&GAX_ram->fx_channels[curfxch].fxid = fxid;
        GAX_ram->fx_channels[curfxch].fxch.priority = 0;
        GAX_ram->fx_channels[curfxch].fxvol = 255;
        GAX_ram->fx_indexes[curfxch] = fxid;
    } else if (GAX_ram->params->flags & GAX_SPEECH) {
        GAX_ram->speech_unk[0x1E6] = fxid - 0x100;
        GAX_ram->speech_unk[0x1E7] = 0;
        GAX_ram->speech_unk[0x1E8] = 0;
    } else if (GAX_ram->params->debug) {
        GAX_ASSERT(GAX_str_GAX_FX, GAX_str_SPEECH_FX);
    }
    return curfxch;
}

u32 GAX_fx_ex(u32 fxid, s32 fxch, s32 prio, s32 note)
{
    int i;
    int curfxch = -1;
    int prio1, prio2;

    prio2 = prio;
    if (fxch == -1) {
        for (i = 0; i < GAX_ram->num_fx_channels; i++) {
            prio1 = GAX_ram->fx_channels[i].fxch.priority;
            if (prio1 <= prio2) {
                curfxch = i;
                prio2 = prio1;
            }
        }
    } else {
        curfxch = fxch;
        if (curfxch >= GAX_ram->num_fx_channels)
            curfxch = -1;
        if (curfxch == -1)
            return -1;
        if (prio < GAX_ram->fx_channels[curfxch].fxch.priority)
            curfxch = -1;
    }
    if (curfxch != -1) {
        GAX_ram->fx_channels[curfxch].fxfreq = note != -1 ? (note >> 5) + 2 : 8;
        GAX_ram->fx_channels[curfxch].fxnote = note != -1 ? note & 31 : 0;
        GAX_ram->fx_channels[curfxch].nofixedfreq = note != -1;
        *(u8 *)&GAX_ram->fx_channels[curfxch].fxid = fxid;
        GAX_ram->fx_channels[curfxch].fxch.priority = prio;
        GAX_ram->fx_channels[curfxch].fxvol = 255;
        GAX_ram->fx_indexes[curfxch] = fxid;
    }
    return curfxch;
}

u32 GAX2_fx(const GAXFXParams *fxparams)
{
    u16 fxid;
    s32 fxch, prio, note, vol;
    u32 val;
    u32 ch;

    if (fxparams == NULL) {
        GAX_ASSERT(GAX_str_GAX2_FX, GAX_str_FXPARAMS_NULL);
        return -1;
    }
    if (fxparams->fxid == 0xFFFF)
        GAX_ASSERT(GAX_str_GAX2_FX, GAX_str_FXID_DEFAULT);
    fxid = fxparams->fxid;
    val = fxparams->fxch;
    fxch = -1;
    if (val != 0xFFFF)
        fxch = val;
    val = fxparams->prio;
    prio = val != (u32)-1 ? val : 0x7FFFFFFF;
    val = fxparams->note;
    note = -1;
    if (val != (u32)-1)
        note = val;
    vol = fxparams->volume != 0xFFFF ? fxparams->volume : 255;
    if (vol > 255)
        vol = 255;
    ch = GAX_fx_ex(fxid, fxch, prio, note);
    if (ch == (u32)-1)
        return -1;
    GAX_ram->fx_channels[ch].fxvol = vol;
    return ch;
}

u32 GAX_fx_status(s32 fxch)
{
    if (fxch < 0 || fxch >= GAX_ram->num_fx_channels)
        return 0;
    if (GAX_ram->fx_channels[fxch].fxch.priority == 1 << 31)
        GAX_ram->fx_indexes[fxch] = 0;
    return GAX_ram->fx_indexes[fxch];
}

void GAX_set_music_volume(s32 ch, u32 vol)
{
    int i;
    if (vol > 255)
        vol = 255;
    if (ch == -1) {
        for (i = 0; i < GAX_ram->replayer[GAX_ram->mix_buffer_id]->song_2->num_channels; i++)
            GAX_ram->replayer[GAX_ram->mix_buffer_id]->channels[i].mixing_volume = vol;
    } else if (ch > -2 && ch < GAX_ram->replayer[GAX_ram->mix_buffer_id]->song_2->num_channels) {
        GAX_ram->replayer[GAX_ram->mix_buffer_id]->channels[ch].mixing_volume = vol;
    }
}

void GAX_ASSERT_PRINT(int x, int y, const char *string)
{
    u16 *vram = (u16 *)(0x06000000 + x + x + y * 64);
    u8 c, t, m;
    while ((c = *string) != 0) {
        int i = 0;
        int col = ((u32)vram & 63) >> 1;
        u8 ch = *string;
        const char *next = string + 1;
        if (col < 32) {
            t = c;
            goto test;
        loop:
            col++, i++;
            if (col > 31)
                goto done;
            t = string[i];
        test:
            if (t == 0 || t == ' ' || t == '\n')
                goto done;
            if (col <= 29)
                goto loop;
            vram = (u16 *)(((u32)vram & -64) + 64);
        }
    done:
        m = ch;
        string = next;
        if (m == '_')
            m = 93;
        if (m == ':')
            m = 92;
        if (m == '.')
            m = 91;
        if (m == '\n')
            vram = (u16 *)(((u32)vram & -64) + 63);
        if (m == ' ')
            m = 0;
        else if (m <= 64)
            m = m - 47;
        else if (m > 96)
            m = m - 86;
        else if (m > 64)
            m = m - 54;
        *vram++ = m;
    }
}

extern const u8 GAX_font[];
extern const char *const GAX_version_banner;
#define REG_BLDCNT   (*(vu16 *)0x04000050)
#define REG_BLDALPHA (*(vu16 *)0x04000052)
#define REG_BLDY     (*(vu16 *)0x04000054)
#define REG_BG0HOFS  (*(vu16 *)0x04000010)
#define REG_BG0VOFS  (*(vu16 *)0x04000012)
#define REG_DMA0CNT_H_ALIAS (*(vu16 *)0x040000EA)
void GAX_ASSERT(const char *fn, const char *msg)
{
    u32 zero;
    u16 prev = 0;
    const void *src;
    void *dst;
    u16 keys;
    s32 i;
    const char *const *banner;
    register u16 *p asm("r0");

    REG_IME = prev;
    REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    REG_DMA2CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA2CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    REG_DMA3CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA3CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    REG_DMA0CNT_H_ALIAS = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA0CNT_H_ALIAS = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    { void *d = (void *)0x06000000; zero = prev; CpuFastSet(&zero, d, 0x01004000); }
    src = GAX_font;
    dst = (void *)0x06004000;
    p = dst;
    asm volatile("mov r7, r0\n\tmov r8, r1\n\tldr r0, %0\n\tldr r1, %1\n\tswi 0x13\n\tmov r0, r7\n\tmov r1, r8"
                 : : "m"(src), "m"(dst), "r"(p) : "r8");
    banner = &GAX_version_banner;
    { u16 z = 0; for (i = 15; i >= 0; i--)
        *p++ = z; }
    *(vu32 *)0x060044B8 = 0x1000;
    *(vu32 *)0x060044C8 = 0x10000;
    *(vu32 *)0x060044D4 = 0x10000;
    *(vu32 *)0x060044FC = 0x01111110;
    GAX_ASSERT_PRINT(0, 0, *banner);
    GAX_ASSERT_PRINT(0, 5, GAX_str_FUNCTION_NAME);
    GAX_ASSERT_PRINT(15, 5, fn);
    GAX_ASSERT_PRINT(0, 7, msg);
    *(vu16 *)0x05000002 = 0;
    *(vu16 *)0x05000000 = 0x7FFF;
    REG_BG0CNT = 4;
    REG_DISPCNT = 0x100;
    REG_BLDCNT = 0;
    REG_BLDALPHA = 0;
    REG_BLDY = 0;
    REG_BG0HOFS = 0;
    REG_BG0VOFS = 0;
    for (;;) {
        u16 k = REG_KEYINPUT ^ 0x3FF;
        u16 pressed = k & ~prev;
        prev = k;
        if (pressed & 8)
            asm volatile("mov r0, #0\n\tswi 0");
    }
}

void GAX_clear_mem(u32 dest, u32 size)
{
    u32 zero;
    int n;
    int rest;
    u8 *p;
    while (dest & 3) {
        *(u8 *)dest = 0;
        dest++, size--;
    }
    zero = 0;
    n = size & -32;
    CpuFastSet(&zero, (void *)dest, ((n / 4) & 0x1FFFFF) | (1 << 24));
    p = (u8 *)(dest + n);
    rest = size - n;
    if (rest > 0) {
        while (rest != 0) {
            *p++ = 0;
            rest--;
        }
    }
}

void GAX2_new_fx(GAXFXParams *fxparams)
{
    if (fxparams == NULL) {
        GAX_ASSERT(GAX_str_GAX2_NEW_FX, GAX_str_FXPARAMS_NULL);
    } else {
        fxparams->fxid = -1;
        fxparams->fxch = -1;
        fxparams->prio = -1;
        fxparams->note = -1;
        fxparams->volume = -1;
    }
}

u32 GAX_get_free_mem(void)
{
    return GAX_ram->scratch_mem_size;
}

/* GAX_pause: mute Direct Sound outputs and stop the mixing DMA(s). */
void sub_08318FF8(void)
{
    if (GAX_ram->irq_state == 0)
        return;
    GAX_ram->irq_state = 0;
    if (GAX_ram->buf_header_dma2)
        REG_SOUNDCNT_H &= ~(SOUND_A_LEFT_OUTPUT | SOUND_A_RIGHT_OUTPUT | SOUND_B_LEFT_OUTPUT | SOUND_B_RIGHT_OUTPUT);
    else
        REG_SOUNDCNT_H &= ~(SOUND_A_LEFT_OUTPUT | SOUND_A_RIGHT_OUTPUT);
    REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    if (GAX_ram->buf_header_dma2) {
        REG_DMA2CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        GAX_DMA_DELAY();
        REG_DMA2CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    }
}


/* GAX_resume: flush the FIFOs and re-enable the Direct Sound outputs. */
void sub_08319078(void)
{
    int i;
    if (!GAX_ram->irq_state) {
        GAX_ram->irq_state = 1;
        if (GAX_ram->buf_header_dma2) {
            for (i = 0; i < 8; i++) {
                REG_FIFO_A = 0;
                REG_FIFO_B = 0;
            }
            REG_SOUNDCNT_H |= SOUND_A_LEFT_OUTPUT | SOUND_A_RIGHT_OUTPUT | SOUND_B_LEFT_OUTPUT | SOUND_B_RIGHT_OUTPUT;
        } else {
            for (i = 0; i < 8; i++)
                REG_FIFO_A = 0;
            REG_SOUNDCNT_H |= SOUND_A_LEFT_OUTPUT | SOUND_A_RIGHT_OUTPUT;
        }
    }
}


/* GAX_pause_music: freeze the music tracker; sound effects keep playing. */
void sub_083190E0(void)
{
    GAX_ram->playback_state = GAX_PAUSED;
}


/* GAX_resume_music */
void sub_083190F0(void)
{
    GAX_ram->playback_state = GAX_RESUMED;
}

void GAX_fx_note(s32 fxch, s32 note)
{
    if ((u32)note < 3821 && fxch > -1 && fxch < GAX_ram->num_fx_channels) {
        if (GAX_ram->fx_channels[fxch].fxch.instrument) {
            GAX_ram->fx_channels[fxch].fxch.cur_pitch = note;
            GAX_ram->fx_channels[fxch].nofixedfreq = TRUE;
        }
    }
}

void GAX_stop_fx(s32 fxch)
{
    int i;
    if (fxch == -1) {
        for (i = 0; i < GAX_ram->num_fx_channels; i++)
            GAX_ram->fx_channels[i].fxfreq = 1;
    } else if (fxch < GAX_ram->num_fx_channels && fxch >= 0) {
        GAX_ram->fx_channels[fxch].fxfreq = 1;
    }
}

void GAX_set_fx_volume(s32 fxch, u32 vol)
{
    int i;
    if (vol > 255)
        vol = 255;
    if (fxch == -1) {
        for (i = 0; i < GAX_ram->num_fx_channels; i++)
            GAX_ram->fx_channels[i].fxch.mixing_volume = vol;
    } else if (fxch > -2 && fxch < GAX_ram->num_fx_channels) {
        GAX_ram->fx_channels[fxch].fxch.mixing_volume = vol;
    }
}

/* GAX_stop: stop playback, sound hardware, mixing DMA(s) and sample-rate timer(s). */
void sub_08319214(void)
{
    GAX_player *player = GAX_ram->replayer[GAX_ram->mix_buffer_id];

    player->is_playing = FALSE;
    GAX_ram->irq_state = 0;
    REG_SOUNDCNT_X = 0;
    REG_DMA1CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    GAX_DMA_DELAY();
    REG_DMA1CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    if (GAX_ram->buf_header_dma2 != NULL) {
        REG_DMA2CNT_H = DMA_ENABLE | DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
        GAX_DMA_DELAY();
        REG_DMA2CNT_H = DMA_DEST_FIXED | DMA_REPEAT | DMA_32BIT;
    }
    REG_TM0CNT = 0;
    if (GAX_ram->buf_header_dma2 != NULL)
        REG_TM1CNT = 0;
}
