/*
 * GAX 3.01 functions that are decompiled but do not yet match byte-for-byte.
 *
 * The ROM is still built from asm/ for these (see splits.txt). The C below is the current
 * best attempt: same control flow and data accesses as the original, with register
 * allocation / stack layout differences left. It is not linked into the matching build;
 * `make nonmatching` compiles it so it doesn't rot, and the PC/PS1 ports can use it.
 * When one matches, move it into its object's C file and drop it from here.
 */
#include "gax.h"

/* ---- GAX2_calc_mem (083175A8) ---- */

extern const u8 GAX_default_song[];
extern const u16 GAX_table[13 * 2];
extern u8 GAXOutput_render_asm_0831A100[], GAXOutput_render_asm_end_0831A220[];
extern u8 GAXOutput_lowpass_asm_0831A220[], GAXOutput_lowpass_asm_end_0831A2EC[];
extern u8 GAXOutput_reverb_asm_0831A2EC[], GAXOutput_reverb_asm_end_0831A3E8[];
extern u8 GAXTracker_asm_0831A3FC[], GAXTracker_asm_end_0831A470[];
extern u8 GAXTracker_pingpong_asm_0831A470[], GAXTracker_pingpong_asm_end_0831A528[];

void GAX2_calc_mem(GAXParams *params)
{
    u32 size = 0;
    u32 rate;
    u32 fxrate;
    u32 fxch;
    u32 rev;
    const GAXSongData *song;
    u32 i, j;
    u32 differ = 0;
    const u16 *table;

    if (params->song_data == NULL)
        params->song_data = GAX_default_song;
    if (params->mixing_rate == 0xFFFF) {
        rate = ((const GAXSongData *)params->song_data)->mixing_rate;
        song = params->song_data;
    } else {
        rate = params->mixing_rate;
        song = params->song_data;
    }
    for (j = 0; j < 13; j++) {
        if (GAX_table[j * 2] >= rate) {
            i = j;
            goto found1;
        }
    }
    i = 12;
found1:
    rate = GAX_table[i * 2];
    if (params->fx_mixing_rate == 0xFFFF) {
        fxrate = rate;
        if (song->fx_mixing_rate)
            fxrate = song->fx_mixing_rate;
    } else {
        fxrate = params->fx_mixing_rate;
    }
    for (j = 0; j < 13; j++) {
        if (GAX_table[j * 2] >= fxrate) {
            i = j;
            goto found2;
        }
    }
    i = 12;
found2:
    fxrate = GAX_table[i * 2];
    if ((const u8 *)song == GAX_default_song)
        rate = fxrate;
    if (fxrate != rate)
        differ = 1;
    if (params->fx_channels == 0xFFFF)
        fxch = song->fx_channels;
    else
        fxch = params->fx_channels;
    if (params->fx_data == NULL) {
        fxch = 0;
        params->fx_channels = 0;
    }
    size += 0x8C;
    size += GAX_ALIGN(fxch, 4);
    size += fxch * sizeof(GAX_FX_channel);
    if (params->flags & GAX_SPEECH)
        size += 0x7A4;
    size += 8;
    if (differ)
        size += 8;
    size += ((((fxrate > rate) ? fxrate : rate) * 1000 / 59727) + 4) * 2;
    size += (rate * 1000 / 59727) * 2;
    if (differ)
        size += (fxrate * 1000 / 59727) * 2;
    if (!(params->flags & GAX_NO_JINGLES) && song->unkC4) {
        rev = song->unkBC;
        size += sizeof(GAX_player);
        size += song->unkC4 * sizeof(GAX_channel);
    } else {
        rev = song->unkC0;
    }
    if (rev) {
        size += (rev * rate / 1000) * 2;
        size = GAX_ALIGN(size, 4);
        size += GAXOutput_reverb_asm_end_0831A3E8 - GAXOutput_reverb_asm_0831A2EC;
    }
    if (params->flags & GAX_LOWPASS_FILTER)
        size += GAXOutput_lowpass_asm_end_0831A2EC - GAXOutput_lowpass_asm_0831A220;
    size += GAXOutput_render_asm_end_0831A220 - GAXOutput_render_asm_0831A100;
    size += GAXTracker_asm_end_0831A470 - GAXTracker_asm_0831A3FC;
    size += GAXTracker_pingpong_asm_end_0831A528 - GAXTracker_pingpong_asm_0831A470;
    size += sizeof(GAX_player);
    size += song->num_channels * sizeof(GAX_channel);
    params->workmem_size = size;
}

/* ---- GAX2_init (08317CD8) ---- */

extern const u8 GAX_default_song[];
extern const u16 GAX_table[13 * 2];
extern const char *const GAX_copyright;
extern u8 GAXOutput_render_asm_0831A100[], GAXOutput_render_asm_end_0831A220[];
extern u8 GAXOutput_lowpass_asm_0831A220[], GAXOutput_lowpass_asm_end_0831A2EC[];
extern u8 GAXOutput_reverb_asm_0831A2EC[], GAXOutput_reverb_asm_end_0831A3E8[];
extern u8 GAXTracker_asm_0831A3FC[], GAXTracker_asm_end_0831A470[];
extern u8 GAXTracker_pingpong_asm_0831A470[], GAXTracker_pingpong_asm_end_0831A528[];
void GAXFx_open(GAX_FX_channel *fxch);

#define MEMCLR(dest_, size_) { \
    u8 *p_ = (u8 *)(dest_); \
    s32 n_ = (size_); \
    s32 al_, k_; \
    while ((u32)p_ & 3) { *p_++ = 0; n_--; } \
    zero = 0; \
    al_ = n_ & -32; \
    CpuFastSet(&zero, p_, ((al_ / 4) & 0x1FFFFF) | (1 << 24)); \
    { u8 *q_ = p_ + al_; for (k_ = 0; k_ < n_ - al_; k_++) *q_++ = 0; } \
}

b8 GAX2_init(GAXParams *params)
{
    const GAXSongData *song;
    const void *fx_data;
    u32 i = 0, j;
    u32 zero;
    u32 rev;
    u32 size;

    GAX_ram = (struct GAX_RAM *)params->workmem;
    if (params->song_data == NULL)
        params->song_data = GAX_default_song;
    fx_data = params->fx_data;
    if (fx_data == NULL)
        params->fx_channels = 0;
    if (params->mixing_rate == 0xFFFF)
        params->mixing_rate = ((const GAXSongData *)params->song_data)->mixing_rate;
    if (params->fx_mixing_rate == 0xFFFF && fx_data != NULL) {
        u16 r = ((const GAXSongData *)params->song_data)->fx_mixing_rate;
        if (r == 0)
            r = params->mixing_rate;
        params->fx_mixing_rate = r;
    }
    if (params->fx_channels == 0xFFFF)
        params->fx_channels = ((const GAXSongData *)params->song_data)->fx_channels;
    if (params->volume == 0xFFFF)
        params->volume = 255;

    for (j = 0; j < 13; j++)
        if (GAX_table[j * 2] >= params->mixing_rate) {
            i = j;
            goto found1;
        }
    i = 12;
found1:
    params->mixing_rate = GAX_table[i * 2];
    if (fx_data != NULL) {
        for (j = 0; j < 13; j++)
            if (GAX_table[j * 2] >= params->fx_mixing_rate) {
                i = j;
                goto found2;
            }
        i = 12;
    found2:
        params->fx_mixing_rate = GAX_table[i * 2];
    }
    if ((const u8 *)params->song_data == GAX_default_song)
        params->mixing_rate = params->fx_mixing_rate;
    if (params->fx_mixing_rate != params->mixing_rate && (params->flags & (GAX_HALFRATE_FX | GAX_FX_REVERB))) {
        if (params->debug)
            GAX_ASSERT(GAX_str_GAX2_INIT, GAX_str_FX_MIXING_RATE);
        return FALSE;
    }

    GAX_ram->scratch_mem = params->workmem + (GAX_ALIGN(params->fx_channels, 4) + 0x8C);
    GAX_ram->scratch_mem_size = params->workmem_size - 0x8C - GAX_ALIGN(params->fx_channels, 4);
    GAX_ram->signature = 0x47415833;
    GAX_ram->params = params;
    GAX_ram->irq_state = 0;
    GAX_ram->mix_buffer_id = 0;
    GAX_ram->reverb_enabled = FALSE;
    GAX_ram->playback_state = 0;
    GAX_ram->unk5B = 0;
    GAX_ram->irq_finished = TRUE;
    GAX_ram->fx_pitch = 0;
    GAX_ram->music_pitch = 0;
    for (i = 0; i < params->fx_channels; i++)
        GAX_ram->fx_indexes[i] = 0;
    if (params->fx_data != NULL) {
        GAX_ram->fx_data = (GAXSongData *)params->fx_data;
        GAX_ram->fx_channels = (GAX_FX_channel *)GAX_alloc(params->fx_channels * sizeof(GAX_FX_channel));
        GAX_ram->num_fx_channels = params->fx_channels;
    } else {
        GAX_ram->fx_data = NULL;
        GAX_ram->fx_channels = NULL;
        GAX_ram->num_fx_channels = 0;
    }
    GAX_ram->fx_reverb = FALSE;
    if ((params->flags & GAX_SPEECH) && params->fx_data != NULL)
        GAX_ram->speech_unk = (u32 *)GAX_alloc(0x7A4);
    GAX_ram->buf_header_dma1 = (GAX_playback_buffer *)GAX_alloc(sizeof(GAX_playback_buffer));
    if (GAX_ram->fx_data != NULL && params->fx_mixing_rate != params->mixing_rate)
        GAX_ram->buf_header_dma2 = (GAX_playback_buffer *)GAX_alloc(sizeof(GAX_playback_buffer));
    else
        GAX_ram->buf_header_dma2 = NULL;
    params->mixermode = GAX_ram->buf_header_dma2 != NULL;

    for (j = 0; j < 13; j++)
        if (GAX_table[j * 2] >= params->mixing_rate) {
            i = j;
            goto found3;
        }
    i = 12;
found3:
    GAX_ram->buf_header_dma1->unused = 8;
    GAX_ram->buf_header_dma1->update = TRUE;
    GAX_ram->buf_header_dma1->mixrate = GAX_table[i * 2];
    GAX_ram->buf_header_dma1->timer_reload = GAX_ram->buf_header_dma1->mixrate * 1000 / 59727;
    GAX_ram->timer_reload_dma1 = GAX_table[i * 2 + 1];
    if (GAX_ram->buf_header_dma2 != NULL) {
        for (j = 0; j < 13; j++)
            if (GAX_table[j * 2] >= params->fx_mixing_rate) {
                i = j;
                goto found4;
            }
        i = 12;
    found4:
        GAX_ram->buf_header_dma2->unused = 8;
        GAX_ram->buf_header_dma2->update = TRUE;
        GAX_ram->buf_header_dma2->mixrate = GAX_table[i * 2];
        GAX_ram->buf_header_dma2->timer_reload = GAX_ram->buf_header_dma2->mixrate * 1000 / 59727;
        GAX_ram->timer_reload_dma2 = GAX_table[i * 2 + 1];
    }
    /* tamper check: a modified copyright string detunes the music */
    if (GAX_copyright[2] != 'X' || GAX_copyright[1] != 'A' || GAX_copyright[0] != 'G')
        GAX_ram->timer_reload_dma1 <<= 1;

    if (GAX_ram->buf_header_dma2 != NULL) {
        u16 a = GAX_ram->buf_header_dma1->timer_reload;
        u16 b = GAX_ram->buf_header_dma2->timer_reload;
        size = ((a > b ? a : b) + 4) * 2;
    } else {
        size = (GAX_ram->buf_header_dma1->timer_reload + 4) * 2;
    }
    GAX_ram->mix_buffer = GAX_alloc(size);
    GAX_ram->buffer_half = 0;
    GAX_ram->buffer_dma1 = (u32)GAX_alloc(GAX_ram->buf_header_dma1->timer_reload * 2);
    MEMCLR((void *)GAX_ram->buffer_dma1, GAX_ram->buf_header_dma1->timer_reload * 2);
    if (GAX_ram->buf_header_dma2 != NULL) {
        GAX_ram->buffer_dma2 = (u32)GAX_alloc(GAX_ram->buf_header_dma2->timer_reload * 2);
        MEMCLR((void *)GAX_ram->buffer_dma2, GAX_ram->buf_header_dma2->timer_reload * 2);
    }

    song = params->song_data;
    if (!(params->flags & GAX_NO_JINGLES) && song->unkC4)
        rev = song->unkBC;
    else
        rev = song->unkC0;
    if (rev) {
        GAX_ram->reverb_enabled = TRUE;
        rev = rev * GAX_ram->buf_header_dma1->mixrate / 1000;
        GAX_ram->reverb_buf = GAX_alloc(rev * 2);
        GAX_ram->reverb_buf_size = rev * 2;
        MEMCLR(GAX_ram->reverb_buf, rev * 2);
        GAX_ram->reverb_asm = GAX_code2ram(GAXOutput_reverb_asm_0831A2EC, GAXOutput_reverb_asm_end_0831A3E8);
    }
    if (params->flags & GAX_LOWPASS_FILTER)
        GAX_ram->lowpass_asm = GAX_code2ram(GAXOutput_lowpass_asm_0831A220, GAXOutput_lowpass_asm_end_0831A2EC);
    else
        GAX_ram->lowpass_asm = NULL;
    GAX_ram->render_asm = GAX_code2ram(GAXOutput_render_asm_0831A100, GAXOutput_render_asm_end_0831A220);
    GAX_ram->gax_tracker_asm = GAX_code2ram(GAXTracker_asm_0831A3FC, GAXTracker_asm_end_0831A470);
    GAX_ram->gax_pingpong_asm = GAX_code2ram(GAXTracker_pingpong_asm_0831A470, GAXTracker_pingpong_asm_end_0831A528);
    GAX_ram->filt_depth = 0;
    GAX2_init_song((GAXSongData *)params->song_data);
    GAX_ram->jingle_mem = GAX_ram->scratch_mem;
    GAX_ram->jingle_mem_size = GAX_ram->scratch_mem_size;
    GAX_open();
    if (GAX_ram->buf_header_dma2 != NULL)
        GAX_ram->current_buf = GAX_ram->buf_header_dma2;
    for (i = 0; i < GAX_ram->num_fx_channels; i++)
        GAXFx_open(&GAX_ram->fx_channels[i]);
    GAX2_init_soundhw();
    GAX_ram->irq_state = 1;
    GAX_PLAYER()->stop_on_songend = (params->flags >> 3) & 1;
    GAX_ram->params->is_songend = FALSE;
    GAX_ram->params->is_jingleend = FALSE;
    if ((params->flags & GAX_FX_REVERB) && ((const GAXSongData *)params->song_data)->reverb_channels)
        GAX_ram->fx_reverb = TRUE;
    else
        GAX_ram->fx_reverb = FALSE;
    return TRUE;
}

/* ---- GAXSync_render (083192C0) ---- */
/* 6 instructions off: only the order of 'speed_timer = t - 1' vs the zero constant and the
   'speed = t' copy differ. new_var is a second pointer to the player (see docs/gax.md). */

u32 GAXSync_render(GAX_player *player, u32 timer)
{
  GAXSongData *song;
  u16 speed;
  u8 speed_timer;
  GAX_player *new_var;
  u8 speed_lo;
  if ((player->timer_backup != timer) && player->is_playing)
  {
    speed_lo = player->speed_buf;
    speed = player->speed_buf;
    new_var = player;
    speed_timer = new_var->speed_timer;
    if ((speed_lo != 0) && ((new_var->songend = 0, ((s32) (speed_timer << 24)) <= 0)))
    {
      if (new_var->skip_pattern)
      {
        new_var->skip_pattern = 0;
        new_var->step = new_var->song->num_steps_per_pattern;
        song = new_var->song;
      }
      else
      {
        new_var->step++;
        song = new_var->song;
      }
      if ((new_var->speed_buf >> 8) != 0)
      {
        new_var->speed_buf = (new_var->speed_buf >> 8) | ((new_var->speed_buf & 0xFF) << 8);
      }
      { u16 t = new_var->speed_buf; new_var->speed_timer = t; new_var->speed_timer--; speed = t; }
      if (new_var->step >= song->num_steps_per_pattern)
      {
        new_var->step = 0;
        new_var->new_step_idx = 0;
        new_var->pattern_finished = 1;
        new_var->pattern++;
        if (((s16) new_var->pattern) >= song->num_patterns_per_channel)
        {
          if (new_var->stop_on_songend)
          {
            new_var->is_playing = 0;
            new_var->speed_buf = 0;
          }
          new_var->songend = 1;
          new_var->pattern = song->loop_point;
          speed = new_var->speed_buf;
        }
      }
      else
      {
        new_var->pattern_finished = 0;
      }
      new_var->step_finished = 1;
    }
    else
    {
      new_var->speed_timer = speed_timer - 1;
      new_var->step_finished = 0;
    }
    if ((speed & 0xFF) == 0)
    {
      new_var->songend = 1;
    }
    new_var->timer_backup = timer;
    if (new_var->first_timer == 0)
    {
      new_var->first_timer = timer;
    }
    if (new_var->unknown_delay)
    {
      new_var->unknown_delay--;
    }
  }
  return 0;
}

/* ---- GAXTracker_generate_audio (08319C60) ---- */

extern const u32 GAX_freqtable[12 * 32];
/* 0831A3E8: ARM helper returning the high word of a 32x32 multiply (umull); called through a
   constant address, hence _call_via_r3 in the original. */
typedef struct GAX_wave {
    const u8 *data;
    u32 length;
} GAX_wave;
typedef struct MixArgs {
    const u8 *src;
    void *mix_buffer;
    u32 count;
    s32 pos;
    s32 loop_len;
    u32 volume;
    s32 step;
} MixArgs;
b8 GAXTracker_generate_audio(GAX_channel *ch, GAX_player *player, GAXSongData *song, b8 is_fx)
{
    GAX_instrument *ins = ch->instrument;
    const GAX_wave *wave;
    s32 pitch;
    s32 freq;
    u32 vol;
    u32 vb;
    s32 step;
    b8 looped;
    s32 end;
    MixArgs args;
    MixArgs *a;
    u32 ofs;
    u8 volenv, wavevol, instvol, mixvol, global;

    if (ins == NULL || ch->semitone_pitch == -30000 || ch->waveslot_idx > 3)
        return FALSE;
    wave = (const GAX_wave *)((u8 *)song->waveform_data + ins->waves[ch->waveslot_idx] * 8);
    if (wave->data == NULL)
        return FALSE;
    pitch = ch->semitone_pitch + ch->vibrato_pitch;
    if (!ch->is_fixed) {
        pitch += ch->cur_pitch;
        if (!is_fx)
            pitch += ch->order[(s16)player->pattern].transpose << 5;
    }
    pitch += ch->instrument->wave_params[ch->waveslot_idx].tune;
    if (pitch > 0xEF1)
        pitch = 0xEF1;
    if (pitch < 0)
        pitch = 0;
    if (pitch > 0xD7F) {
        freq = GAX_freqtable[pitch - 0xD80] << 1;
    } else {
        s32 shift = 0;
        pitch -= 0xC00;
        while (pitch < 0) {
            pitch += 384;
            shift++;
        }
        freq = GAX_freqtable[pitch] >> shift;
    }
    volenv = ch->volenv_volume;
    wavevol = ch->wave_volume;
    instvol = ch->instrument_volume;
    mixvol = ch->mixing_volume;
    global = player->global_volume;
    ofs = is_fx * 4;
    a = &args;
    vol = ((((volenv * wavevol >> 8) * instvol >> 8) * mixvol >> 8) * global) >> 8;
    if (!is_fx)
        vol = (song->volume * vol) >> 8;
    vb = GAX_ram->volboost_level;
    vol >>= vb;
    GAX_ram->dc_correction_val += vol << vb;
    step = ((u32 (*)(u32, u32, u32))0x0831A3E8)(freq, *(u32 *)((u8 *)&GAX_ram->music_pitch + ofs), ofs);
    looped = FALSE;
    if (!ch->instrument->wave_params[ch->waveslot_idx].modulation
        && ch->instrument->wave_params[ch->waveslot_idx].min < ch->instrument->wave_params[ch->waveslot_idx].max)
        looped = TRUE;
    end = wave->length << 11;
    a->mix_buffer = GAX_ram->mix_buffer;
    a->count = GAX_ram->current_buf->timer_reload;
    a->volume = vol;
    a->step = step;
    if (looped) {
        end = ch->instrument->wave_params[ch->waveslot_idx].max << 11;
        a->loop_len = (ch->instrument->wave_params[ch->waveslot_idx].max - ch->instrument->wave_params[ch->waveslot_idx].min) << 11;
    }
    if (ch->enable_modulation) {
        end = (ch->modulate_position + ch->instrument->wave_params[ch->waveslot_idx].mod_size) << 11;
        a->loop_len = ch->instrument->wave_params[ch->waveslot_idx].mod_size << 11;
    }
    a->src = wave->data + (end >> 11);
    a->pos = ch->wave_position - end;
    if (!looped && !ch->enable_modulation)
        a->loop_len = (a->src - ((const GAX_wave *)song->waveform_data)->data) << 11;
    if (!ch->enable_modulation && looped && ch->instrument->wave_params[ch->waveslot_idx].pingpong) {
        a->step *= ch->wave_direction;
        ((void (*)(MixArgs *))GAX_ram->gax_pingpong_asm)(a);
        if (a->step < 0) {
            ch->wave_direction = -1;
            ch->wave_position = a->pos + end - a->loop_len;
        } else {
            ch->wave_direction = 1;
            ch->wave_position = a->pos + end;
        }
        return TRUE;
    }
    ((void (*)(MixArgs *))GAX_ram->gax_tracker_asm)(a);
    ch->wave_position = a->pos + end;
    if (ch->wave_position < 0) {
        ch->semitone_pitch = -30000;
        ch->wave_porta_val = 0;
        if (ch->perfstep_speed == 0)
            ch->priority = 1 << 31;
    }
    return TRUE;
}

/* ---- GAXFx_render (08319F88) ---- */

void GAXTracker_process_perflist(GAX_channel *ch);
void GAXTracker_process_frame(GAX_channel *ch);
b8 GAXTracker_generate_audio(GAX_channel *ch, GAX_player *player, GAXSongData *song, b8 is_fx);
#define ch (&fx->fxch)
b8 GAXFx_render(GAX_FX_channel *fx, GAX_player *player)
{
    u8 instr;
    GAX_instrument *ins;
    GAXChannelInfo *ci;

    if (player->unknown_delay)
        ch->instrument = NULL;
    if (player->is_playing && (fx->fxfreq == 1 || (fx->fxfreq != 0 && *(u8 *)&fx->fxid != 0))
        && !player->unknown_delay) {
        if (fx->fxfreq == 1) {
            if (ch->instrument && ch->instrument->volume_envelope->sustain_point == 0xFF) {
                ch->semitone_pitch = -30000;
                ch->wave_porta_val = 0;
                ch->priority = 1 << 31;
                ch->instrument = NULL;
            }
            ch->is_note_off = TRUE;
        } else if (fx->fxfreq > 1) {
            ch->cur_pitch = (fx->fxfreq - 2) << 5;
            ch->is_note_off = FALSE;
        }
        instr = *(u8 *)&fx->fxid;
        if (instr) {
            ins = GAX_ram->fx_data->instrument_data[instr];
            ch->instrument = ins;
            ch->volenv_timer = 0;
            ch->vibtable_index = 0;
            ch->vibrato_wait = ins->vibrato_wait;
            ch->cur_perfstep = 0;
            ch->perflist_timer = 0;
            ch->perfstep_loop = 0;
            ch->instrument_volume = 255;
            ch->is_note_off = FALSE;
            ch->toneporta_lerp = 0;
            ch->target_pitch = 0;
            ch->perfstep_speed = ins->perfstep_speed;
            if (ins->blank) {
                ch->instrument = NULL;
            } else {
                ci = GAX_ram->params->channel_info;
                if (ci != NULL && ch->channel_index >= 0)
                    ci[ch->channel_index].instrument = instr;
            }
        }
        if (fx->fxfreq > 1)
            ch->cur_pitch += fx->fxnote;
        ch->instrument_volume = fx->fxvol;
        ch->vol_slide_val = 0;
        ch->porta_val = 0;
        *(u8 *)&fx->fxid = 0;
        fx->fxnote = 0;
        fx->fxfreq = 0;
    }
    if (ch->instrument != NULL && ch->perflist_timer == 0) {
        if (ch->perfstep_speed == 0)
            goto frame;
        GAXTracker_process_perflist(ch);
        ch->perflist_timer = ch->perfstep_speed - 1;
    } else {
        ch->perflist_timer--;
    }
frame:
    GAXTracker_process_frame(ch);
    if (fx->nofixedfreq)
        ch->is_fixed = FALSE;
    if (ch->ignore)
        return FALSE;
    return GAXTracker_generate_audio(ch, player, GAX_ram->fx_data, TRUE);
}
#undef ch
