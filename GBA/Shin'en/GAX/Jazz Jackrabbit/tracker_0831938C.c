#include "gax.h"

typedef struct ReverbArgs {
    u32 size;
    void *mix_buffer;
    u8 *reverb_buf;
    u32 reverb_buf_size;
    u32 *reverb;
    u32 dc_in;
    u32 dc_out;
} ReverbArgs;
b8 GAXTracker_render(GAX_channel *ch, GAX_player *player);
b8 GAXFx_render(GAX_FX_channel *fxch, GAX_player *player);
b8 GAXOutput_render(GAX_player *player)
{
    b8 rendered = FALSE;
    u32 i;
    s32 j;

    if (GAX_ram->buf_id <= 1 && GAX_ram->playback_state == GAX_RESUMED) {
        for (i = 0; i < player->song_2->reverb_channels; i++)
            rendered |= GAXTracker_render(&player->channels[i], player);
    }
    if (GAX_ram->fx_reverb) {
        for (i = 0; i < GAX_ram->num_fx_channels; i++)
            rendered |= GAXFx_render(&GAX_ram->fx_channels[i], player);
    }
    if (GAX_ram->buf_id <= 1) {
        if (player->song_2->reverb_channels) {
            ReverbArgs args;
            args.size = GAX_ram->current_buf->timer_reload * GAX_ram->current_buf->update * 2;
            args.mix_buffer = GAX_ram->mix_buffer;
            args.reverb_buf = GAX_ram->reverb_buf;
            args.reverb_buf_size = GAX_ram->reverb_buf_size;
            args.reverb = &player->reverb_channels;
            args.dc_in = GAX_ram->dc_correction_val;
            GAX_ram->dc_correction_val += 0x100;
            args.dc_out = GAX_ram->dc_correction_val;
            ((void (*)(ReverbArgs *))GAX_ram->reverb_asm)(&args);
        }
        if (GAX_ram->buf_id <= 1 && GAX_ram->playback_state == GAX_RESUMED) {
            for (j = player->song_2->reverb_channels; j < player->song_2->num_channels; j++)
                rendered |= GAXTracker_render(&player->channels[j], player);
        }
    }
    if (!GAX_ram->fx_reverb && (GAX_ram->buf_id == 0 || GAX_ram->buf_id == 2)) {
        for (i = 0; i < GAX_ram->num_fx_channels; i++)
            rendered |= GAXFx_render(&GAX_ram->fx_channels[i], player);
    }
    if (GAX_ram->playback_state == 1)
        GAX_ram->playback_state = GAX_RESUMED;
    return rendered;
}

void GAXOutput_open(GAX_player *player)
{
    player->timer = 1;
}

typedef struct RenderArgs {
    void *mix_buffer;
    u32 dest;
    u32 size;
    u32 dc_correction_val;
} RenderArgs;
b8 GAXOutput_render(GAX_player *player);
void GAXOutput_stream(GAX_player *player, u32 dest)
{
    u32 size = GAX_ram->current_buf->timer_reload * GAX_ram->current_buf->update;
    GAX_ram->dc_correction_val = 0;
    GAX_clear_mem((u32)GAX_ram->mix_buffer, size << 1);
    if (GAXOutput_render(player)) {
        RenderArgs args;
        args.mix_buffer = GAX_ram->mix_buffer;
        args.dest = dest;
        args.size = size;
        args.dc_correction_val = GAX_ram->dc_correction_val;
        ((void (*)(RenderArgs *))GAX_ram->render_asm)(&args);
    } else {
        GAX_clear_mem(dest, size);
    }
}

void GAXTracker_open(GAX_channel *ch)
{
    ch->wave_position = 0;
    ch->waveslot_idx = 0;
    ch->instrument = NULL;
    ch->semitone_pitch = -30000;
    ch->wave_direction = 1;
    ch->instrument_volume = 255;
    ch->mixing_volume = -1;
    ch->ignore = FALSE;
    ch->enable_modulation = FALSE;
    ch->rle_delay = 0;
    ch->empty_track = FALSE;
    ch->delay_frames = 0;
    ch->toneporta_lerp = 0;
    ch->target_pitch = 0;
    ch->priority = 1 << 31;
    ch->unk1 = 0;
    if (GAX_ram->music_pitch == 0)
        GAX_ram->music_pitch = 0x100000000ULL / GAX_ram->current_buf->mixrate;
}

void GAXTracker_process_step(GAX_channel *ch, GAX_player *player, b8 delayed);
void GAXTracker_process_perflist(GAX_channel *ch);
void GAXTracker_process_frame(GAX_channel *ch);
b8 GAXTracker_generate_audio(GAX_channel *ch, GAX_player *player, GAXSongData *song, b8 is_fx);
b8 GAXTracker_render(GAX_channel *ch, GAX_player *player)
{
    if (player->unknown_delay)
        ch->instrument = NULL;
    if (player->is_playing) {
        if (ch->delay_frames != 0 && --ch->delay_frames == 0)
            GAXTracker_process_step(ch, player, TRUE);
        if (player->speed_buf != 0 && player->step_finished)
            GAXTracker_process_step(ch, player, FALSE);
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
    if (ch->ignore)
        return FALSE;
    return GAXTracker_generate_audio(ch, player, player->song, 0);
}

void GAXTracker_process_step(GAX_channel *ch, GAX_player *player, b8 delayed)
{
    u8 note, instr, fx_type, fx_param;
    u8 *seq;
    GAX_instrument *ins;
    GAXChannelInfo *ci;
    GAXSongData *song;

    ch->vol_slide_val = 0;
    ch->porta_val = 0;
    ch->delay_frames = 0;
    if (!delayed) {
        if (player->pattern_finished) {
            ch->sequence = (u8 *)player->song->track_data + ch->order[(s16)player->pattern].sequence_offset;
            ch->rle_delay = 0;
            ch->empty_track = *ch->sequence;
            ch->sequence++;
        }
        if (ch->empty_track)
            return;
        if (ch->rle_delay) {
            ch->rle_delay--;
            return;
        }
        seq = ch->sequence;
        if (seq[0] == 0xFF) {
            ch->rle_delay = seq[1] - 1;
            ch->sequence = seq + 2;
            return;
        }
        if (seq[0] & 0x80) {
            if ((seq[0] & 0x7F) == 0) {
                ch->sequence = seq + 1;
                return;
            }
            if ((seq[0] & 0x7F) <= 121) {
                note = seq[0] & 0x7F;
                instr = seq[1];
                fx_param = 0;
                fx_type = 0;
                ch->sequence = seq + 2;
            } else {
                note = 0;
                instr = 0;
                fx_type = seq[1];
                fx_param = seq[2];
                ch->sequence = seq + 3;
            }
        } else {
            note = seq[0];
            instr = seq[1];
            fx_type = seq[2];
            fx_param = seq[3];
            ch->sequence = seq + 4;
        }
        if (fx_type == 14 && (fx_param >> 4) == 13) {
            ch->delay_frames = fx_param & 15;
            ch->next_semitone = note;
            ch->next_instrument = instr;
            return;
        }
    } else {
        note = ch->next_semitone;
        instr = ch->next_instrument;
        fx_param = 0;
        fx_type = 0;
    }
    if (fx_type != 3) {
        if (note == 1) {
            if (ch->instrument && ch->instrument->volume_envelope->sustain_point == 0xFF) {
                ch->semitone_pitch = -30000;
                ch->wave_porta_val = 0;
                ch->priority = 1 << 31;
                ch->instrument = NULL;
            }
            ch->is_note_off = TRUE;
        } else if (note > 1) {
            ch->cur_pitch = (note - 2) << 5;
            ch->is_note_off = FALSE;
        }
    }
    song = player->song;
    if (instr) {
        ins = song->instrument_data[instr];
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
    switch (fx_type) {
    case 1:
        ch->porta_val = fx_param;
        break;
    case 2:
        ch->porta_val = -fx_param;
        break;
    case 3:
        if (fx_param) {
            ch->target_pitch = (note - 2) << 5;
            ch->toneporta_lerp = (ch->target_pitch - ch->cur_pitch) / fx_param;
        }
        break;
    case 7:
        player->speed_buf = (fx_param >> 4) | ((fx_param << 8) & 0xF00);
        player->speed_timer = player->speed_buf - 1;
        break;
    case 10:
        ch->vol_slide_val = fx_param;
        break;
    case 11:
        ch->vol_slide_val = -fx_param;
        break;
    case 12:
        ch->instrument_volume = fx_param;
        break;
    case 13:
        player->skip_pattern = TRUE;
        player->new_step_idx = fx_param;
        break;
    case 15:
        player->speed_buf = fx_param;
        player->speed_timer = fx_param - 1;
        break;
    }
}

void GAXTracker_process_perflist(GAX_channel *ch)
{
    GAX_instrument *ins = ch->instrument;
    const GAX_perfstep *step;
    GAX_wave_param *wave;
    u32 i;

    if (ch->cur_perfstep >= ins->perfstep_count) {
        ch->perfstep_speed = 0;
        if (ch->semitone_pitch == -30000)
            ch->priority = 1 << 31;
    } else {
    step = &ins->perflist[ch->cur_perfstep];
    ch->cur_perfstep++;
    if (step->note) {
        ch->semitone_pitch = (step->note - 2) << 5;
        ch->is_fixed = step->fixed;
        if (step->wave_idx) {
            ch->waveslot_idx = step->wave_idx - 1;
            wave = &ins->wave_params[ch->waveslot_idx];
            ch->wave_position = 0;
            ch->wave_direction = 1;
            ch->wave_volume = 255;
            ch->enable_modulation = FALSE;
            if (wave->modulation && wave->min < wave->max && wave->mod_size > 0 && wave->mod_speed && wave->mod_step) {
                s32 init;
                ch->enable_modulation = TRUE;
                init = wave->init;
                ch->modulate_position = init;
                ch->wave_position = init << 11;
                ch->modulate_timer = wave->mod_speed;
                ch->modulate_direction = 1;
                if (init + wave->mod_size > wave->max)
                    ch->modulate_direction = -1;
            } else {
                ch->wave_position = wave->init << 11;
            }
        }
    }
    ch->wave_vol_slide_val = 0;
    ch->wave_porta_val = 0;
    for (i = 0; i < 2; i++) {
        u32 cmd = step->commands[i];
        if (cmd >> 8) {
            u32 param = cmd & 0xFF;
            switch (cmd >> 8) {
            case 1:
                ch->wave_porta_val = param;
                break;
            case 2:
                ch->wave_porta_val = -param;
                break;
            case 5:
                if (ch->perfstep_loop == 0 || --ch->perfstep_loop != 0)
                    ch->cur_perfstep = param;
                break;
            case 6:
                if (ch->perfstep_loop == 0)
                    ch->perfstep_loop = param ? param + 1 : 0;
                break;
            case 10:
                ch->wave_vol_slide_val = param;
                break;
            case 11:
                ch->wave_vol_slide_val = -param;
                break;
            case 12:
                ch->wave_volume = param;
                break;
            case 15:
                ch->perfstep_speed = param;
                break;
            }
        }
    }
    }
}

u8 GAXTracker_process_envelope(GAX_channel *ch, const GAX_volenv *env, u16 *pos)
{
    u16 t = (*pos)++;
    int i, last;
    const GAX_volenv_point *cur, *prev;
    s32 lerp;

    if (env->sustain_point != 0xFF && !ch->is_note_off && t == env->points[env->sustain_point].x)
        *pos = t;
    last = env->point_count - 1;
    if (t >= env->points[last].x) {
        if (env->points[last].volume == 0 && (env->loop_end == 0xFF || env->loop_end < last)) {
            ch->semitone_pitch = -30000;
            ch->wave_porta_val = 0;
            ch->priority = 1 << 31;
        }
        *pos = t;
    }
    if (!ch->is_note_off && env->loop_start != 0xFF && env->loop_end != 0xFF
        && t == env->points[env->loop_end].x)
        *pos = env->points[env->loop_start].x;
    i = 0;
    while (env->points[i].x < t)
        i++;
    if (t == env->points[i].x)
        return env->points[i].volume;
    return ((env->points[i].lerp * (t - env->points[i - 1].x)) >> 8) + env->points[i - 1].volume;
}

extern const s8 GAX_vibtable[64];
u8 GAXTracker_process_envelope(GAX_channel *ch, const GAX_volenv *env, u16 *pos);
void GAXTracker_process_frame(GAX_channel *ch)
{
    s32 v;
    if (ch->instrument) {
        s32 vib;
        ch->volenv_volume = GAXTracker_process_envelope(ch, ch->instrument->volume_envelope, &ch->volenv_timer);
        vib = ch->instrument->vibrato_depth;
        if (vib) {
            if (ch->vibrato_wait <= 0)
                ch->vibtable_index = (ch->vibtable_index + ch->instrument->vibrato_speed) & 63;
            else
                ch->vibrato_wait--;
            vib = GAX_vibtable[ch->vibtable_index] * ch->instrument->vibrato_depth >> 8;
        }
        ch->vibrato_pitch = vib;
        if (ch->enable_modulation && (ch->modulate_timer--, (s8)ch->modulate_timer <= 0)) {
            s32 old = ch->modulate_position;
            GAX_instrument *ins = ch->instrument;
            ch->modulate_timer = ins->wave_params[ch->waveslot_idx].mod_speed;
            if (ch->modulate_direction > 0) {
                ch->modulate_position += ins->wave_params[ch->waveslot_idx].mod_step;
                if (ch->modulate_position + ins->wave_params[ch->waveslot_idx].mod_size > ins->wave_params[ch->waveslot_idx].max) {
                    ch->modulate_position -= ins->wave_params[ch->waveslot_idx].mod_step * 2;
                    ch->modulate_direction = -1;
                }
            } else {
                ch->modulate_position -= ins->wave_params[ch->waveslot_idx].mod_step;
                if (ch->modulate_position < ins->wave_params[ch->waveslot_idx].min) {
                    ch->modulate_position += ins->wave_params[ch->waveslot_idx].mod_step * 2;
                    ch->modulate_direction = 1;
                }
            }
            ch->wave_position = ch->wave_position - (old << 11) + (ch->modulate_position << 11);
        }
    }
    v = ch->vol_slide_val + ch->instrument_volume;
    if (v > 255)
        v = 255;
    if (v < 0)
        v = 0;
    ch->instrument_volume = v;
    v = ch->wave_vol_slide_val + ch->wave_volume;
    if (v > 255)
        v = 255;
    if (v < 0)
        v = 0;
    ch->wave_volume = v;
    ch->cur_pitch += ch->porta_val;
    ch->semitone_pitch += ch->wave_porta_val;
    if (ch->toneporta_lerp) {
        u32 a = (ch->target_pitch - ch->cur_pitch) & 0x80000000;
        ch->cur_pitch += ch->toneporta_lerp;
        if (a != ((ch->target_pitch - ch->cur_pitch) & 0x80000000)) {
            ch->toneporta_lerp = 0;
            ch->cur_pitch = ch->target_pitch;
            ch->target_pitch = 0;
        }
    }
}
