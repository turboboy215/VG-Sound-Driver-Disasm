#include "gax.h"

void GAXSync_open(GAX_player *player)
{
    player->first_timer = 0;
    player->timer_backup = 0;
    player->is_playing = FALSE;
    player->unknown_delay = 0;
    player->stop_on_songend = FALSE;
    player->songend = FALSE;
    player->pattern = -1;
    player->step = 20000;
    player->speed_timer = 0;
    player->speed_buf = 6;
    player->global_volume = 255;
    player->step_finished = FALSE;
    player->pattern_finished = FALSE;
    player->skip_pattern = FALSE;
    player->new_step_idx = 0;
}
