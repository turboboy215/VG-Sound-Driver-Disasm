# Per-game addresses for the Agenda sound driver
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # the Agenda folder (ROMs + .asm)
GAMES = {
 'dora2': dict(
    name='Doraemon 2 (J)', rom='Doraemon 2 (J).gb', bank=1,
    start=0x4000, end=0x7F31,         # sound region (end exclusive)
    hram=0xFF90, wram=0xC100, save_wram=0xC200,
    version=1, rest=0x00,
    jumptab=0x4000, jt_order=['Sound_Init','Sound_Update','Sound_PlayMusic','Sound_PlaySfx',
                              'Sound_StopMusic','Sound_SaveMusic','Sound_RestoreMusic'],
    music_tab=0x492B, music_n=0x20, sfx_tab=0x77E1, sfx_n=0x40,
    cmd_tab=0x41C5, len_tab=0x4105, len_n=14, freq_tab=0x4113, freq_n=89,
    wavevol_tab=0x40F5, init_regs=0x40D3, silent_tab=0x40E7,
    remap=(0x4020, 0x405F),
    extra=[('sfx',0x7991),('sfx',0x7C91)],     # game-side id remap table (read from bank 0)
 ),
 'poko': dict(
    name='Pokonyan! - Yume no Daibouken (J)', rom='Pokonyan! - Yume no Daibouken (J) [S].gb', bank=7,
    start=0x4000, end=0x7C30,
    hram=0xFFB0, wram=0xDD00, save_wram=0xDE00,
    version=2, rest=0x7F,
    jumptab=0x4002, jt_order=['Sound_Update','Sound_StopMusic','Sound_PlaySfx','Sound_Init',
                              'Sound_PlayMusic','Sound_SaveMusic','Sound_RestoreMusic'],
    music_tab=0x4960, music_n=0x11, sfx_tab=0x4EEA, sfx_n=0x22,
    cmd_tab=0x41EB, len_tab=0x4126, len_n=19, freq_tab=0x4139, freq_n=89,
    wavevol_tab=0x4116, init_regs=0x40F4, silent_tab=0x4108,
    remap=None,
    extra=[('song',(0x5F21,0x5FDE,0x6088,0x60FF))],
 ),
}
def load(g):
    c=dict(GAMES[g]); d=open(os.path.join(ROOT, c['rom']),'rb').read()
    off=c['bank']*0x4000-0x4000
    c['bin']=d; c['off']=off
    c['b']=lambda a: d[a+off]
    c['w']=lambda a: d[a+off]|d[a+off+1]<<8
    return c
